#include "objectHF.hlsli"


float4 main( PixelInputType PSIn) : SV_TARGET
{
	float3 normal = normalize(PSIn.nor);
	//uint mat = PSIn.mat;
	float4 spec = g_xMat_specular;
	float4 baseColor = g_xMat_diffuseColor;

	PSIn.tex *= g_xMat_texMulAdd.xy;
	PSIn.tex += g_xMat_texMulAdd.zw;
	
		[branch]if(g_xMat_hasTex){
			baseColor *= xTextureMap.Sample(sampler_aniso_wrap, PSIn.tex);
		}
		baseColor.rgb *= PSIn.instanceColor;

		ALPHATEST(baseColor.a)

		float3 eyevector = normalize(g_xCamera_CamPos - PSIn.pos3D);
		float2 screenPos;
			screenPos.x = PSIn.pos2D.x/PSIn.pos2D.w/2.0f + 0.5f;
			screenPos.y = -PSIn.pos2D.y/PSIn.pos2D.w/2.0f + 0.5f;
		


		//NORMALMAP
		float3 bumpColor=0;
		if(g_xMat_hasNor){
			float4 nortex = xNormalMap.Sample(sampler_aniso_wrap,PSIn.tex);
			if(nortex.a>0){
				float3x3 tangentFrame = compute_tangent_frame(normal, eyevector, -PSIn.tex.xy);
				bumpColor = 2.0f * nortex.rgb - 1.0f;
				//bumpColor.g*=-1;
				normal = normalize(mul(bumpColor, tangentFrame));
			}
		}

		

		//ENVIROMENT MAP
		float4 envCol=0;
		{
			uint mip=0;
			float2 size;
			float mipLevels;
			texture_env_global.GetDimensions(mip,size.x,size.y,mipLevels);

			float3 ref = normalize(reflect(-eyevector, normal));
			envCol = texture_env_global.SampleLevel(sampler_linear_clamp,ref,(1-smoothstep(0,128, g_xMat_specular_power))*mipLevels);
			baseColor = lerp(baseColor,envCol, g_xMat_metallic*spec);
		}
		
	
		//REFRACTION 
		float2 perturbatedRefrTexCoords = screenPos.xy + (normalize(PSIn.nor2D).rg + bumpColor.rg) * g_xMat_refractionIndex;
		float4 refractiveColor = (xRefraction.SampleLevel(sampler_linear_clamp, perturbatedRefrTexCoords, 0));
		baseColor.rgb=lerp(refractiveColor.rgb,baseColor.rgb,baseColor.a);
		
		baseColor.rgb=pow(abs(baseColor.rgb),GAMMA);
		baseColor.a=1;
		
		float depth = PSIn.pos2D.z;
		

		//SPECULAR
		if(g_xMat_hasSpe && !g_xMat_shadeless){
			spec = xSpecularMap.Sample(sampler_aniso_wrap, PSIn.tex);
		}
		[branch]if(!g_xMat_shadeless.x){
			baseColor.rgb*=clamp( saturate( abs(dot(g_xWorld_SunDir.xyz,PSIn.nor)) * g_xWorld_SunColor.rgb ), g_xWorld_Ambient.rgb,1 );
			applySpecular(baseColor, g_xWorld_SunColor, normal, eyevector, g_xWorld_SunDir.xyz, 1, g_xMat_specular_power, spec.w, 0);
		}
		
		baseColor.rgb = pow(abs(baseColor.rgb*(1 + g_xMat_emissive)), INV_GAMMA);

		baseColor.rgb = applyFog(baseColor.rgb,getFog(getLinearDepth(depth/PSIn.pos2D.w)));

	return baseColor;
}