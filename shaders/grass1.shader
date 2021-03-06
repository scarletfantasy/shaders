﻿Shader "Unlit/grass1"
{
    
	
    
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BottomColor("bottomcolor",Color) = (1,1,1,1)
        _TopColor("topcolor",Color) = (1,1,1,1)
        _BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2
        _BladeWidth("Blade Width", Float) = 0.05
        _BladeWidthRandom("Blade Width Random", Float) = 0.02
        _BladeHeight("Blade Height", Float) = 0.5
        _BladeHeightRandom("Blade Height Random", Float) = 0.3
        _TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1
        _WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
        _WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
        _WindStrength("Wind Strength", Float) = 1
        _BladeForward("Blade Forward Amount", Float) = 0.38
        _BladeCurve("Blade Curvature Amount", Range(1, 4)) = 2

    }
    SubShader
    {
        Cull Off
        
        
        Pass
        {
            Tags
			{
				"RenderType" = "Opaque"
				"LightMode" = "ForwardBase"
			}
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull hull
            #pragma domain domain
            #pragma geometry geo
            #pragma target 4.6
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase

            #define BLADE_SEGMENTS 3
            
	        #include "Autolight.cginc"
            #include "Shaders/CustomTessellation.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            
            float rand(float3 co)
	        {
		        return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	        }
            float3x3 AngleAxis3x3(float angle, float3 axis)
	        {
		        float c, s;
		        sincos(angle, s, c);

		        float t = 1 - c;
		        float x = axis.x;
		        float y = axis.y;
		        float z = axis.z;

		        return float3x3(
			        t * x * x + c, t * x * y - s * z, t * x * z + s * y,
			        t * x * y + s * z, t * y * y + c, t * y * z - s * x,
			        t * x * z - s * y, t * y * z + s * x, t * z * z + c
			        );
	        }
            
            struct geometryOutput
            {
	            float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                
            };
            
            

            sampler2D _MainTex;
            float4 _MainTex_ST,_BottomColor, _TopColor;
            float _BendRotationRandom;
            float _BladeHeight;
            float _BladeHeightRandom;	
            float _BladeWidth;
            float _BladeWidthRandom;
            sampler2D _WindDistortionMap;
            float4 _WindDistortionMap_ST;
            float2 _WindFrequency;
            float _WindStrength;
            float _BladeForward;
            float _BladeCurve;

           
            geometryOutput VertexOutput(float3 pos,float2 uv)
            {
	            geometryOutput o;
	            o.pos = UnityObjectToClipPos(pos);
                o.uv=uv;
                
	            return o;
            }
            geometryOutput GenerateGrassVertex(float3 vertexPosition, float width, float height,float forward, float2 uv, float3x3 transformMatrix)
            {
	            float3 tangentPoint = float3(width, forward, height);

	            float3 localPosition = vertexPosition + mul(transformMatrix, tangentPoint);
	            return VertexOutput(localPosition, uv);
            }
            [maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
            void geo(triangle vertexOutput IN[3] : SV_POSITION, inout TriangleStream<geometryOutput> triStream)
            {
                geometryOutput o;

                // Add to the top of the geometry shader.
                float3 pos = IN[0].vertex;
                float3 vNormal = IN[0].normal;
                float4 vTangent = IN[0].tangent;
                float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;
                float3x3 tangentToLocal = float3x3(
	            vTangent.x, vBinormal.x, vNormal.x,
	            vTangent.y, vBinormal.y, vNormal.y,
	            vTangent.z, vBinormal.z, vNormal.z
	            );
                float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom * UNITY_PI * 0.5, float3(-1, 0, 0));
                float3x3 facingRotationMatrix =AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));
                float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
                float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;
                float3 wind = normalize(float3(windSample.x, windSample.y, 0));
                float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample, wind);
                float3x3 transformationMatrix = mul(mul(mul(tangentToLocal, windRotation), facingRotationMatrix), bendRotationMatrix);
               float3x3 transformationMatrixFacing = mul(tangentToLocal, facingRotationMatrix);
               float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
                float width = (rand(pos.xzy) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
                float forward = rand(pos.yyz) * _BladeForward;
                for (int i = 0; i < BLADE_SEGMENTS; i++)
                {
	                float t = i / (float)BLADE_SEGMENTS;
                    float segmentHeight = height * t;
                    float segmentWidth = width * (1 - t);
                    float segmentForward = pow(t, _BladeCurve) * forward;
                    float3x3 transformMatrix = i == 0 ? transformationMatrixFacing : transformationMatrix;

                    triStream.Append(GenerateGrassVertex(pos, segmentWidth, segmentHeight,segmentForward,  float2(0, t), transformMatrix));
                    triStream.Append(GenerateGrassVertex(pos, -segmentWidth, segmentHeight,segmentForward,  float2(1, t), transformMatrix));
                }
                triStream.Append(GenerateGrassVertex(pos, 0, height,forward, float2(0.5, 1), transformationMatrix));
                
            }
            fixed4 frag (geometryOutput i) : SV_Target
            {
                
                return lerp(_BottomColor, _TopColor, i.uv.y);
            }
            ENDCG
        }
        
    }
}
