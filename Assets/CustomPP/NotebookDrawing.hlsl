#define Res float2(_MainTex_TexelSize.zw)
#define Res1 float2(_NoiseTex_TexelSize.zw)

#define AngleNum 3
#define SampNum 16
#define PI2 6.28318530717959

float4 getRand(float2 pos,SamplerState sampler_NoiseTex)
{
	return SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, pos / Res1 / Res.y*1080.);
}

float4 getCol(float2 pos,SamplerState sampler_MainTex)
{
	// take aspect ratio into account
	float2 uv = ((pos - Res.xy*.5) / Res.y*Res.y) / Res.xy + .5;
	float4 c1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
	float4 e = smoothstep(float4(-0.05, -0.05, -0.05, -0.05), float4(0.0, 0.0, 0.0, 0.0), float4(uv, float2(1.0, 1.0) - uv));
	c1 = lerp(float4(1, 1, 1, 0), c1, e.x*e.y*e.z*e.w);
	float d = clamp(dot(c1.xyz, float3(-.5, 1., -.5)), 0.0, 1.0);
	float4 c2 = float4(.7,.7,.7,.7);
	return min(lerp(c1, c2, 1.8*d), .7);
}

float4 getColHT(float2 pos,SamplerState sampler_MainTex,SamplerState sampler_NoiseTex)
{
	return smoothstep(.95, 1.05, getCol(pos,sampler_MainTex)*.8 + .2 + getRand(pos*.7,sampler_NoiseTex));
}

float getVal(float2 pos,SamplerState sampler_MainTex)
{
	float4 c = getCol(pos,sampler_MainTex);
	return pow(dot(c.xyz, float3(.333, .333, .333)), 1.)*1.;
}

float2 getGrad(float2 pos, float eps,SamplerState sampler_MainTex)
{
	float2 d = float2(eps, 0);
	return float2(
		getVal(pos + d.xy,sampler_MainTex) - getVal(pos - d.xy,sampler_MainTex),
		getVal(pos + d.yx,sampler_MainTex) - getVal(pos - d.yx,sampler_MainTex)
		) / eps / 2.;
}

void Convolution_float(float2 pos, SamplerState sampler_MainTex,SamplerState sampler_NoiseTex, out float3 color1, out float3 color2) 
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
					g = getGrad(pos2, .4,sampler_MainTex);
				fact = dot(g, v) - .5*abs(dot(g, v.yx*float2(1, -1)));
				fact2 = dot(normalize(g + float2(.0001,.0001)), v.yx*float2(1, -1));

				fact = clamp(fact, 0., .05);
				fact2 = abs(fact2);

				fact *= 1. - float(j) / float(SampNum);
				col += fact;
				col2 += fact2*getColHT(pos3,sampler_MainTex,sampler_NoiseTex).xyz;
				sum += fact2;
			}
		}
	}
	col /= float(SampNum*AngleNum)*.75 / sqrt(Res.y);
	col2 /= sum;
	col.x *= (.6 + .8*getRand(pos*.7,sampler_NoiseTex).x);
	col.x = 1. - col.x;
	col.x *= col.x*col.x;

	color1 = col;
	color2 = col2;
}