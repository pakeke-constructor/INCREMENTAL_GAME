// The MIT License (MIT)

// Copyright (c) 2015 Wesley LaFerriere
// Copyright (c) 2025 Miku AuahDark, modified for LOVE compatibility.

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "GLSL-CRT"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

uniform vec2 CRT_CURVE_AMNT; // curve amount
uniform float CRT_CURVE_AMNTx; // curve amount on x
uniform float CRT_CURVE_AMNTy; // curve amount on y
uniform float SCAN_LINE_MULT;
uniform float SCAN_LINE_STRENGTH;

uniform sampler2D u_texture;

vec4 effect(vec4 v_color, Image u_texture, vec2 tc, vec2 sc) {
	// Distance from the center
    vec2 d = abs(0.5 - tc);

	// Square it to smooth the edges
    d *= d;

    tc -= 0.5;
    tc *= 1.0 + (d.yx * CRT_CURVE_AMNT);
    tc += 0.5;

	// Get texel, and add in scanline if need be
	vec4 cta = Texel(u_texture, tc);

	cta.rgb += sin(tc.y * SCAN_LINE_MULT) * SCAN_LINE_STRENGTH;

	// Cutoff
	if(tc.y > 1.0 || tc.x < 0.0 || tc.x > 1.0 || tc.y < 0.0) {
        float tx = max(tc.x - 1.0, -tc.x) * 64.0;
        float ty = max(tc.y - 1.0, -tc.y) * 64.0;
        float t = clamp(max(tx, ty), 0.0, 1.0);
		cta = mix(cta, vec4(0.0), t);
    }

	// Apply
	return cta * v_color;
}
