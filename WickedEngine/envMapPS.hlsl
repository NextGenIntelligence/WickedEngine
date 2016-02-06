#include "globals.hlsli"
#include "envMapHF.hlsli"

Texture2D<float4> xTextureTex:register(t3);

float4 main(PSIn input) : SV_TARGET
{
	float4 baseColor = g_xMat_diffuseColor;

	input.tex *= g_xMat_texMulAdd.xy;
	input.tex += g_xMat_texMulAdd.zw;
	
	if (g_xMat_hasTex) {
		baseColor *= xTextureTex.Sample(sampler_aniso_wrap, input.tex.xy);
	}
	baseColor.rgb *= input.instanceColor;

	clip(baseColor.a < 0.1f ? -1 : 1);

	return baseColor*(1 + g_xMat_emissive);
}