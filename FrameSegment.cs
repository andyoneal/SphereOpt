using UnityEngine;

namespace SphereOpt
{
    public struct FrameSegment
    {
        // This uint packs multiple fields:
        // - layer (bits 0-3): 4 bits for layer, valid values are 1 to 11.
        // - state (bits 4-6): 3 bits for state, valid values are 0 to 4.
        // - progress (bit 7): 1 bit for progress, where 0 is false and 1 is true.
        // - color (bits 8-31): 24 bits for RGB color, 8 bits per channel, no alpha.
        public uint layer_state_progress_color;
        public Vector3 pos0;
        public Vector3 pos1;

        public uint layer
        {
            get => layer_state_progress_color & 0xF; // Extract bits 0-3
            set => layer_state_progress_color = (uint)((layer_state_progress_color & ~0xF) | (value & 0xF)); // Set bits 0-3
        }

        public uint state
        {
            get => (layer_state_progress_color >> 4) & 0x7; // Extract bits 4-6
            set => layer_state_progress_color = (uint)((layer_state_progress_color & ~(0x7 << 4)) | ((value & 0x7) << 4)); // Set bits 4-6
        }

        public bool progress
        {
            get => (layer_state_progress_color & 0x80) != 0; // Extract bit 7
            set => layer_state_progress_color = (uint)((layer_state_progress_color & ~0x80) | (value ? 0x80u : 0u)); // Set bit 7
        }

        public Color32 color
        {
            get
            {
                byte r = (byte)((layer_state_progress_color >> 8) & 0xFF); // Extract red channel (bits 8-15)
                byte g = (byte)((layer_state_progress_color >> 16) & 0xFF); // Extract green channel (bits 16-23)
                byte b = (byte)((layer_state_progress_color >> 24) & 0xFF); // Extract blue channel (bits 24-31)
                return new Color32(r, g, b, 255); // Return Color32, assuming alpha is always 255
            }

            // Combine RGB channels into bits 8-31, leaving other bits unchanged
            set => layer_state_progress_color = (layer_state_progress_color & 0xFF) | ((uint)value.r << 8) | ((uint)value.g << 16) | ((uint)value.b << 24);
        }
    }
}