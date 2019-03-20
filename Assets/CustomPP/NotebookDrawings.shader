﻿// Unity3D port of the "notebook drawings" fragment shader created by flockaroo (Florian Berger)
// released on Shadertoy (2016-Sep-21): https://www.shadertoy.com/view/XtVGD1
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// ported by movAX13h
// refactor by movAX13h

Shader "VisualSketch/Notebook Drawings"
{
	HLSLINCLUDE

	//#include "UnityCG.cginc"
	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

	TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
	TEXTURE2D_SAMPLER2D(_NoiseTex, sampler_NoiseTex);
	float4 _MainTex_TexelSize;
	float4 _NoiseTex_TexelSize;
	float _Grid;
	// flockaroo drawing shader starts here --------------

	#define Res float2(_MainTex_TexelSize.zw)
	#define Res0 float2(_MainTex_TexelSize.zw)
	#define Res1 float2(_NoiseTex_TexelSize.zw)

	#define AngleNum 3
	#define SampNum 16
	#define PI2 6.28318530717959

	float4 getRand(float2 pos)
	{
		return SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, pos / Res1 / Res.y*1080.);
	}

	float4 getCol(float2 pos)
	{
		// take aspect ratio into account
		float2 uv = ((pos - Res.xy*.5) / Res.y*Res0.y) / Res0.xy + .5;
		float4 c1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
		float4 e = smoothstep(float4(-0.05, -0.05, -0.05, -0.05), float4(0.0, 0.0, 0.0, 0.0), float4(uv, float2(1.0, 1.0) - uv));
		c1 = lerp(float4(1, 1, 1, 0), c1, e.x*e.y*e.z*e.w);
		float d = clamp(dot(c1.xyz, float3(-.5, 1., -.5)), 0.0, 1.0);
		float4 c2 = float4(.7,.7,.7,.7);
		return min(lerp(c1, c2, 1.8*d), .7);
	}

	float4 getColHT(float2 pos)
	{
		return smoothstep(.95, 1.05, getCol(pos)*.8 + .2 + getRand(pos*.7));
	}

	float getVal(float2 pos)
	{
		float4 c = getCol(pos);
		return pow(dot(c.xyz, float3(.333, .333, .333)), 1.)*1.;
	}

	float2 getGrad(float2 pos, float eps)
	{
		float2 d = float2(eps, 0);
		return float2(
			getVal(pos + d.xy) - getVal(pos - d.xy),
			getVal(pos + d.yx) - getVal(pos - d.yx)
			) / eps / 2.;
	}

	float4 fx(in float2 pos)
	{
		float3 col = float3(0,0,0);
		float3 col2 = float3(0,0,0);
		float sum = 0.;
		for (int i = 0; i<AngleNum; i++)
		{
			float ang = PI2 / float(AngleNum)*(float(i) + .8);
			float2 v = float2(cos(ang), sin(ang));
			for (int j = 0; j<SampNum; j++)
			{
				float2 dpos = v.yx*float2(1, -1)*float(j)*Res.y / 400.;
				float2 dpos2 = v.xy*float(j*j) / float(SampNum)*.5*Res.y / 400.;
				float2 g;
				float fact;
				float fact2;

				for (float s = -1.; s <= 1.; s += 2.)
				{
					float2 pos2 = pos + s*dpos + dpos2;
						float2 pos3 = pos + (s*dpos + dpos2).yx*float2(1, -1)*2.;
						g = getGrad(pos2, .4);
					fact = dot(g, v) - .5*abs(dot(g, v.yx*float2(1, -1)));
					fact2 = dot(normalize(g + float2(.0001,.0001)), v.yx*float2(1, -1));

					fact = clamp(fact, 0., .05);
					fact2 = abs(fact2);

					fact *= 1. - float(j) / float(SampNum);
					col += fact;
					col2 += fact2*getColHT(pos3).xyz;
					sum += fact2;
				}
			}
		}
		col /= float(SampNum*AngleNum)*.75 / sqrt(Res.y);
		col2 /= sum;
		col.x *= (.6 + .8*getRand(pos*.7).x);
		col.x = 1. - col.x;
		col.x *= col.x*col.x;

		float3 karo = float3(1,1,1);
		if (_Grid.x > 0.5)
		{
			float2 s = sin(pos.xy*.1 / sqrt(Res.y / 400.));
			karo -= .5*float3(.25, .1, .1)*dot(exp(-s*s*80.), float2(1, 1));
		}
		float vign = 1.0;
		float r = length(pos - Res.xy*.5) / Res.x;
		vign = max(0.0, vign - 0 * r*r*r);
		return float4(float3(col.x*col2*karo*vign), 1);
	}

	float4 Frag(VaryingsDefault i) : SV_Target
	{
		return fx(i.texcoord * Res);
	}

	ENDHLSL

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			HLSLPROGRAM

			#pragma vertex VertDefault
			#pragma fragment Frag

			ENDHLSL
		}
	}
}
