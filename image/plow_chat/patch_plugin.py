#!/usr/bin/env python3
"""Patch the fleet plow_chat plugin in the base image.

The Sep 12 pin calls `_channel_prompt` from `_prime` without `authority`.
That is a TypeError on every first-install setup turn, which `_serve` logs
only as `websocket error: TypeError` and then reconnects. Reconnects hammer
GET /v1/chats and surface as `grant read failed: ClientResponseError`.
"""
from pathlib import Path

INIT = Path("/opt/hermes/plugins/plow_chat/__init__.py")
TRANSPORT = Path("/opt/hermes/plugins/plow_chat/_transport.py")


def replace_once(text, old, new, label):
    if new.strip() in text and old not in text:
        print(f"patch: {label} already applied")
        return text
    if old not in text:
        raise SystemExit(f"patch: {label}: expected text not found")
    return text.replace(old, new, 1)


def patch_init(text):
    text = replace_once(
        text,
        """        owner_dm = _owner_dm(self._chats[home])
        await self._handoff_message(MessageEvent(
            text=SETUP_TURN,
            source=self.build_source(chat_id=home, chat_name=chat["name"], chat_type=chat["type"],
                                     user_id="plow_setup", user_name="Plow setup",
                                     role_authorized=owner_dm),
            message_id=f"setup-{uuid.uuid4().hex}",
            message_type=_message_type([]),
            channel_prompt=_channel_prompt(chat, "owner" if owner_dm else "member",
                                           self._chats[home], self._identity) + _SILENCE_OPTION,
        ))
""",
        """        owner_dm = _owner_dm(self._chats[home])
        # Same matrix as `_goal_fire`: setup is not a human speaker. Omitting
        # `authority` here TypeError'd the first-install turn and tore the
        # websocket down before the backfilled inbound debounce could hand off.
        authority, recall_everywhere = _authority(chat, owner_dm, human=False)
        event = MessageEvent(
            text=SETUP_TURN,
            source=self.build_source(chat_id=home, chat_name=chat["name"], chat_type=chat["type"],
                                     user_id="plow_setup", user_name="Plow setup",
                                     role_authorized=owner_dm),
            message_id=f"setup-{uuid.uuid4().hex}",
            message_type=_message_type([]),
            channel_prompt=_channel_prompt(chat, "owner" if owner_dm else "member",
                                           self._chats[home], self._identity, authority) + _SILENCE_OPTION,
        )
        event.authority, event.recall_everywhere = authority, recall_everywhere
        await self._handoff_message(event)
""",
        "_prime authority",
    )
    text = replace_once(
        text,
        """                    if owes_prime:
                        owes_prime = False
                        await self._prime()
""",
        """                    if owes_prime:
                        owes_prime = False
                        try:
                            await self._prime()
                        except Exception:
                            log.exception("[plow_chat] setup turn failed; socket stays up")
""",
        "_prime must not kill the socket",
    )
    text = replace_once(
        text,
        """        except _PlowAuthError:
            raise                              # terminal; _listen owns the stop
        except Exception as exc:              # noqa: BLE001 - the caller reconnects
            log.error("[plow_chat] grant read failed: %s", type(exc).__name__)
            raise
""",
        """        except _PlowAuthError:
            raise                              # terminal; _listen owns the stop
        except Exception as exc:              # noqa: BLE001 - the caller reconnects
            status = getattr(exc, "status", None)
            detail = type(exc).__name__ if status is None else f"{type(exc).__name__} HTTP {status}"
            # A blip on GET /v1/chats used to drop a live grant and reconnect
            # every 5s, which is the `grant read failed: ClientResponseError`
            # storm. Keep the last real roster unless this is still the seed.
            live = any((self._chats.get(uid) or {}).get("participants")
                       for uid in self.chat_uids)
            if live and status in {429, 500, 502, 503, 504}:
                log.error("[plow_chat] grant read failed: %s — keeping last grant", detail)
                return
            log.error("[plow_chat] grant read failed: %s", detail)
            raise
""",
        "grant read keep-last",
    )
    text = replace_once(
        text,
        """    async def _on_frame(self, frame, http=None):
        if frame.get("type") == "connected":
            return
""",
        """    async def _on_frame(self, frame, http=None):
        if not isinstance(frame, dict):
            log.warning("[plow_chat] dropped non-object frame: %s", type(frame).__name__)
            return
        if frame.get("type") == "connected":
            return
""",
        "_on_frame dict guard",
    )
    text = replace_once(
        text,
        """        uid = msg["uid"]
        if (chat_uid, uid) in self._seen:
            return                           # socket/backfill overlap - never re-fetch
        if not msg["body"].strip() and not msg["attachments"]:
            return
        if chat_uid not in self._inbound:
            queue = asyncio.Queue()
            server = asyncio.create_task(self._serve_chat(chat_uid, queue))
            server.add_done_callback(_server_died)
            self._inbound[chat_uid] = (queue, server)
        # The fetch starts now, inside the signed urls' five minutes, whatever
        # is retrying ahead of this message; the burst awaits it once it closes.
        self._inbound[chat_uid][0].put_nowait(
            _Inbound(
                uid,
                sender,
                msg["body"].startswith("/"),
""",
        """        uid = msg["uid"]
        if (chat_uid, uid) in self._seen:
            return                           # socket/backfill overlap - never re-fetch
        body = msg.get("body") or ""
        if not body.strip() and not msg.get("attachments"):
            return
        if chat_uid not in self._inbound:
            queue = asyncio.Queue()
            server = asyncio.create_task(self._serve_chat(chat_uid, queue))
            server.add_done_callback(_server_died)
            self._inbound[chat_uid] = (queue, server)
        # The fetch starts now, inside the signed urls' five minutes, whatever
        # is retrying ahead of this message; the burst awaits it once it closes.
        self._inbound[chat_uid][0].put_nowait(
            _Inbound(
                uid,
                sender,
                body.startswith("/"),
""",
        "null message body",
    )
    return text


def patch_transport(text):
    return replace_once(
        text,
        """        except Exception as exc:              # noqa: BLE001 - reconnect, never die
            # TYPE only: the ticket is a query parameter, so a non-101
            # handshake raises an exception carrying the whole URL, and
            # that ticket is still live.
            log.warning("[%s] websocket error: %s", tag, type(exc).__name__)
            on_drop()
""",
        """        except Exception as exc:              # noqa: BLE001 - reconnect, never die
            # Do not stringify the exception: a non-101 handshake carries the
            # ticket URL. Status is safe and is what `grant read failed` hid.
            status = getattr(exc, "status", None)
            detail = type(exc).__name__ if status is None else f"{type(exc).__name__} HTTP {status}"
            log.warning("[%s] websocket error: %s", tag, detail)
            on_drop()
""",
        "websocket error status",
    )


def main():
    init = patch_init(INIT.read_text())
    transport = patch_transport(TRANSPORT.read_text())
    INIT.write_text(init)
    TRANSPORT.write_text(transport)
    print("patch: plow_chat plugin updated")


if __name__ == "__main__":
    main()
