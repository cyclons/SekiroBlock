// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/RacialBlur"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_GradTex ("_GradTexture", 2D) = "white" {}
		_BlurTex("BlurTexture",2d)="white"{}
		_BlurCenter("BlurCenter",vector)=(0.5,0.5,0,0)
		_BlurStrength("BlurStrength",float)=0.5
		_BlurRange("BlurRange",float)=0.3
		_Timer("Timer",float)=1000
		_BlurSpeed("BlurSpeed",float)=1
		_Aspect("Aspect",float)=1
		_BlurCircleRadius("_BlurCircleRadius",float)=1
	}


	CGINCLUDE
			#include "UnityCG.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;
			sampler2D _GradTex;
			sampler2D _BlurTex;
			half4 _MainTex_TexelSize;
			float _BlurStrength;
			float2 _BlurCenter;
			float _Timer;
			float _BlurSpeed;
			float _BlurCircleRadius;
			float _BlurRange;
			float _Aspect;

			float GetBlurPercent(float2 pos){
				float t=_Timer-length(pos-_BlurCenter)/_BlurSpeed;
				t*=1/_BlurCircleRadius;
				return tex2D(_GradTex,float2(t,0)).a;
			}

			fixed4 GetExplosionColor(float2 pos){
				fixed4 yellow = fixed4(1,0.5,0,1);
				float t=_Timer*5;

				return yellow*max(-1*t*t+t,0)*min(0.05/length(pos-_BlurCenter),3 );
			}

			fixed4 frag (v2f i) : SV_Target
			{

				float2 p=i.uv*float2(_Aspect,1);
				float2 dir =normalize(p-_BlurCenter);
				dir*=_MainTex_TexelSize.xy;
				//dir=dir/length(dir);

				fixed4 col =tex2D(_MainTex,i.uv-dir*1) ;
				col +=tex2D(_MainTex,i.uv-dir*2) ;
				col +=tex2D(_MainTex,i.uv-dir*3) ;
				col +=tex2D(_MainTex,i.uv-dir*5) ;
				col +=tex2D(_MainTex,i.uv-dir*8) ;
				col +=tex2D(_MainTex,i.uv+dir*1) ;
				col +=tex2D(_MainTex,i.uv+dir*2) ;
				col +=tex2D(_MainTex,i.uv+dir*3) ;
				col +=tex2D(_MainTex,i.uv+dir*5) ;
				col +=tex2D(_MainTex,i.uv+dir*8) ;
				col *=0.1;

				return col;
			}


			
			struct v2f_lerp
			{
				float4 pos : SV_POSITION;
				float2 uv1 : TEXCOORD0; //uv1
				float2 uv2 : TEXCOORD1; //uv2
			};

			v2f_lerp vert_mix(appdata_img  v){
				v2f_lerp o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv1 = v.texcoord.xy;
				o.uv2 = v.texcoord.xy;
				//dx中纹理从左上角为初始坐标，需要反向(在写rt的时候需要注意)
				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					o.uv2.y = 1 - o.uv2.y;
				#endif
				return o;

			}

			fixed4 frag_mix (v2f_lerp i) : SV_Target{
				fixed4 rawCol = tex2D(_MainTex, i.uv1);
				fixed4 blurCol = tex2D(_BlurTex, i.uv2);
				fixed4 col = lerp(rawCol,blurCol,_BlurStrength
					//获取当前像素点在曲线上的值
					*GetBlurPercent(i.uv1*float2(_Aspect,1))
					//范围限制
					*min(_BlurRange/length(i.uv1*float2(_Aspect,1)-_BlurCenter),1));
				
				//加点黄光
				col+=GetExplosionColor(i.uv1*float2(_Aspect,1));
				return col;
			}

	ENDCG

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			ENDCG
		}

				Pass
		{
			CGPROGRAM
			#pragma vertex vert_mix
			#pragma fragment frag_mix
			
			#include "UnityCG.cginc"

			ENDCG
		}
	}
}
