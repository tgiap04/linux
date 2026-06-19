#ifndef COVERT_FRAMING_H
#define COVERT_FRAMING_H

#include <linux/types.h>

/* Start marker: 0xFF 0x00 — signals beginning of covert message */
#define COVERT_MARKER_START_BYTE0  0xFF
#define COVERT_MARKER_START_BYTE1  0x00

/* End marker: 0x00 0xFF — signals end of covert message (different from start) */
#define COVERT_MARKER_END_BYTE0    0x00
#define COVERT_MARKER_END_BYTE1    0xFF

/* Marker size in bytes */
#define COVERT_MARKER_SIZE         2

/*
 * Framing state for the sender side.
 * Tracks where we are in the message-to-embed sequence.
 */
enum covert_framing_state {
	COVERT_FRAM_IDLE,       /* No message to send */
	COVERT_FRAM_SEND_START, /* Need to send start marker */
	COVERT_FRAM_SEND_DATA,  /* Sending data bytes */
	COVERT_FRAM_SEND_END,   /* Need to send end marker */
};

/*
 * Per-message context used during embedding.
 */
struct covert_framing_ctx {
	enum covert_framing_state state;
	const u8 *message;     /* Pointer to raw message bytes */
	size_t msg_len;        /* Total message length */
	size_t pos;            /* Current position in message */
};

/**
 * covert_framing_init - Initialize framing context for a new message.
 * @ctx:    framing context
 * @msg:    pointer to message bytes
 * @len:    message length in bytes
 */
void covert_framing_init(struct covert_framing_ctx *ctx, const u8 *msg, size_t len);

/**
 * covert_framing_next_byte - Get the next byte to embed.
 * @ctx:    framing context
 * @out:    output byte
 *
 * Returns 0 on success, -1 when message is fully sent.
 * Includes start/end markers as part of the byte stream.
 */
int covert_framing_next_byte(struct covert_framing_ctx *ctx, u8 *out);

/**
 * covert_framing_set_message - Queue a message for embedding.
 * Returns 0 on success, -BUSY if a message is already queued.
 */
int covert_framing_set_message(const u8 *msg, size_t len);

/**
 * covert_framing_clear - Clear the pending message queue.
 * Returns 0 on success.
 */
int covert_framing_clear(void);

/**
 * covert_framing_has_pending - Check if there's a pending message.
 */
int covert_framing_has_pending(void);

/**
 * covert_framing_get_next - Get next byte from the pending message.
 * Returns 0 on success, -1 when done or no message.
 */
int covert_framing_get_next(u8 *out);

#endif /* COVERT_FRAMING_H */
