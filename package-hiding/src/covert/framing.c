#include "framing.h"
#include <linux/spinlock.h>
#include <linux/string.h>

/* Global pending message state */
static struct covert_framing_ctx g_framing;
static DEFINE_SPINLOCK(g_framing_lock);
static u8 g_pending_message[1024];
static size_t g_pending_len;
static int g_has_pending;

/*
 * Framing states for the sender side.
 * Sequence: START_BYTE0 -> START_BYTE1 -> DATA[0..N-1] -> END_BYTE0 -> END_BYTE1
 */
enum covert_fram_phase {
	PHASE_START_B0,   /* Send 0xFF (start marker byte 0) */
	PHASE_START_B1,   /* Send 0x00 (start marker byte 1) */
	PHASE_DATA,       /* Send data bytes */
	PHASE_END_B0,     /* Send 0xFF (end marker byte 0) */
	PHASE_END_B1,     /* Send 0xFF (end marker byte 1) */
};

void covert_framing_init(struct covert_framing_ctx *ctx, const u8 *msg, size_t len)
{
	ctx->state   = COVERT_FRAM_SEND_START;
	ctx->message = msg;
	ctx->msg_len = len;
	ctx->pos     = 0;
}

int covert_framing_next_byte(struct covert_framing_ctx *ctx, u8 *out)
{
	static enum covert_fram_phase phase;
	static int phase_initialized;

	/* First call initializes phase */
	if (!phase_initialized || ctx->state == COVERT_FRAM_SEND_START) {
		phase = PHASE_START_B0;
		phase_initialized = 1;
		ctx->state = COVERT_FRAM_SEND_DATA; /* Mark as started */
	}

	switch (phase) {
	case PHASE_START_B0:
		phase = PHASE_START_B1;
		*out = COVERT_MARKER_START_BYTE0;
		return 0;

	case PHASE_START_B1:
		phase = PHASE_DATA;
		*out = COVERT_MARKER_START_BYTE1;
		return 0;

	case PHASE_DATA:
		if (ctx->pos < ctx->msg_len) {
			*out = ctx->message[ctx->pos];
			ctx->pos++;
			return 0;
		}
		/* All data sent, move to end marker */
		phase = PHASE_END_B0;
		*out = COVERT_MARKER_END_BYTE0;
		return 0;

	case PHASE_END_B0:
		phase = PHASE_END_B1;
		*out = COVERT_MARKER_END_BYTE1;
		return -1; /* Signal: message complete */

	case PHASE_END_B1:
	default:
		return -1;
	}
}

int covert_framing_set_message(const u8 *msg, size_t len)
{
	unsigned long flags;

	if (len > sizeof(g_pending_message))
		return -EINVAL;

	spin_lock_irqsave(&g_framing_lock, flags);
	if (g_has_pending) {
		spin_unlock_irqrestore(&g_framing_lock, flags);
		return -EBUSY;
	}
	memcpy(g_pending_message, msg, len);
	g_pending_len = len;
	g_has_pending = 1;
	spin_unlock_irqrestore(&g_framing_lock, flags);

	pr_info("covert: message queued (%zu bytes)\n", len);
	return 0;
}

int covert_framing_has_pending(void)
{
	return g_has_pending;
}

int covert_framing_get_next(u8 *out)
{
	unsigned long flags;
	int ret = -1;

	spin_lock_irqsave(&g_framing_lock, flags);
	if (!g_has_pending) {
		spin_unlock_irqrestore(&g_framing_lock, flags);
		return -1;
	}

	/* Lazy-init framing context */
	if (g_framing.state == COVERT_FRAM_IDLE || g_framing.state == COVERT_FRAM_SEND_END) {
		covert_framing_init(&g_framing, g_pending_message, g_pending_len);
	}

	ret = covert_framing_next_byte(&g_framing, out);

	if (ret == -1) {
		/* Message fully sent */
		g_has_pending = 0;
		g_framing.state = COVERT_FRAM_IDLE;
		pr_info("covert: message fully embedded\n");
	}

	spin_unlock_irqrestore(&g_framing_lock, flags);
	return ret;
}
