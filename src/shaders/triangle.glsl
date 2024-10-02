@vs vs
layout (location=0) in vec3 aPos;
layout (location=1) in vec3 instPos;
layout (location=2) in float instScale;

uniform vs_params {
	float aspectRatio;
};

out vec3 pos;

void main() {
	gl_Position = vec4(aPos, 1.0f);
	gl_Position.x *= aspectRatio;
	gl_Position.xy /= instScale;
	gl_Position.xyz += instPos;

	pos = aPos;
}
@end

@fs fs
out vec4 FragColor;

in vec3 pos;

void main() {
	if ((pos.x * pos.x) + (pos.y * pos.y) <= 1.0f) {
		FragColor = vec4(1.0f, 0.0f, 0.0f, 1.0f);
	} else {
		discard;
	}
}
@end

@program triangle vs fs
