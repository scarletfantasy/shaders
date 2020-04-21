
Shader "Custom/test" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_NormalTex ("Normal Texture", 2D) = "white" {}
		_RampTex ("Ramp Texture", 2D) = "white" {}
		_SpecularMask ("Specular Mask", 2D) = "white" {}
		_Specular ("Speculr Exponent", Range(0.1, 10)) = 10
		_RimMask ("Rim Mask", 2D) = "white" {}
		_Rim ("Rim Exponent", Range(0.1, 8)) = 1
	}
	SubShader {	
		Pass {
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
 
			sampler2D _MainTex;
			sampler2D _NormalTex;
			sampler2D _RampTex;
			sampler2D _SpecularMask;
			float _Specular;
			sampler2D _RimMask;
			float _Rim;
			
			float4 _MainTex_ST;
			float4 _NormalTex_ST;
			float4 _SpecularMask_ST;
			float4 _RimMask_ST;
			
			struct v2f {
				float4 position : SV_POSITION;
  				float2 uv0 : TEXCOORD0;
  				float2 uv1 : TEXCOORD1;
  				float2 uv2 : TEXCOORD2;
  				float2 uv3 : TEXCOORD3;
  				float3 viewDir : TEXCOORD4;
  				float3 lightDir : TEXCOORD5;
  				float3 up : TEXCOORD6;
			};
			
			v2f vert(appdata_full v) {
				v2f o;
  				o.position = UnityObjectToClipPos (v.vertex);
				o.uv0 = TRANSFORM_TEX (v.texcoord, _MainTex); 
				o.uv1 = TRANSFORM_TEX (v.texcoord, _NormalTex); 
				o.uv2 = TRANSFORM_TEX (v.texcoord, _SpecularMask); 
				o.uv3 = TRANSFORM_TEX (v.texcoord, _RimMask); 
				//法线贴图为tangent空间
				TANGENT_SPACE_ROTATION;
 	 			float3 lightDir = mul (rotation, ObjSpaceLightDir(v.vertex));
 	 			o.lightDir = normalize(lightDir);
				
				float3 viewDirForLight = mul (rotation, ObjSpaceViewDir(v.vertex));
  				o.viewDir = normalize(viewDirForLight);
  				float3 tmp=mul(unity_WorldToObject, half4(0.0, 1.0, 0.0, 0.0));
  				o.up = mul(rotation, tmp);
				
				
				return o;
			}
			
			fixed4 frag (v2f i) : COLOR {
				
				

				half3 k = tex2D( _MainTex, i.uv0).rgb;
				half3 normal = UnpackNormal(tex2D (_NormalTex, i.uv1)); 
				half3 wrapdiffusecol = tex2D(_RampTex, float2(pow(0.5 * dot (normal, i.lightDir) + 0.5, 1),0)).rgb;
				half wrapdiffuse=wrapdiffusecol.r*0.299+wrapdiffusecol.g*0.587+wrapdiffusecol.b*0.114;
				half3 difwrapterm = _LightColor0.rgb *2* wrapdiffuse; 
				half3 dirambienterm = half3(0.5,0.5,0.5);		
				half3 viewindependentterm = k * (dirambienterm + difwrapterm);


				half3 r = reflect(i.lightDir, normal);
				half3 ri = dot(i.viewDir, r);
				half fs = 1.0; 
				half fr = pow(1 - dot(normal, i.viewDir), 4);
				half3 ks = tex2D( _SpecularMask, i.uv2).rgb;
				half3 kr = half3(1.0,1.0,1.0);
				half3 multiplePhongTerms =  _LightColor0.rgb * ks * max(fs * pow(ri, _Specular), kr*fr * pow(ri, _Rim));
				
				
				half3 av = float(1);
				half3 dedicatedRimLighting = dot(normal, i.up) * fr * kr * av;
				half3 viewDependentLightTerms = multiplePhongTerms + dedicatedRimLighting;
	       	  	

	       	  	float4 col;
	       	  	col.rgb = viewindependentterm + viewDependentLightTerms;
	       	  	col.a = 1.0;
	       	  	
	       	  	return col;
			}
 
			ENDCG
		}
	}
	
	FallBack "Diffuse"
}
