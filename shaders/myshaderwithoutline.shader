Shader "Unlit/myshaderwithoutline"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _MainColor("Main Color", Color) = (1,1,1,1)
        _Shininess("shine",Float)=10.0
        _HightlightCol("highlightcolor",Color) = (1,1,1,1)
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineThickness("Outline Thickness", Range(0,.1)) = 0.03
        _Outline("on",int)=0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram
            // make fog work
            #pragma multi_compile_fog
            #pragma shader_feature USE_SPECULAR
            #pragma shader_feature USE_NORMAL
            #include "UnityCG.cginc"
            #include  "UnityStandardBRDF.cginc"
            struct VertexData {
                 float4 position : POSITION;
                 float2 uv : TEXCOORD0;
                 float3 normal : NORMAL;
            };
            struct FragmentData {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainColor;
            float _Shininess;
            float4 _HightlightCol;
            FragmentData MyVertexProgram(VertexData v) {
                FragmentData i;
                //// old version: i.position = mul(UNITY_MATRIX_MVP, v.position);
                i.position = UnityObjectToClipPos(v.position);
                i.uv = TRANSFORM_TEX(v.uv, _MainTex);
                i.normal = UnityObjectToWorldNormal(v.normal);
                i.worldPos = mul(unity_ObjectToWorld, v.position);
                return i;
            }
            float4 MyFragmentProgram(FragmentData i) : SV_TARGET{
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 halfVector = normalize(lightDir + viewDir);
                float3 diffuse = tex2D(_MainTex, i.uv).rgb * lightColor * DotClamped(lightDir, i.normal);
                
                float3 specular = tex2D(_MainTex, i.uv).rgb * _HightlightCol * pow(dot(halfVector, viewDir), _Shininess);
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * tex2D(_MainTex, i.uv).rgb;
                #if USE_NORMAL
                    return float4(i.normal, 1);
                #endif
                return float4(ambient +specular+diffuse, 1);
                
                
            
            }

            
            ENDCG
        }
        Pass{
            Cull front

            CGPROGRAM

                //include useful shader functions
                #include "UnityCG.cginc"

                //define vertex and fragment shader
                #pragma vertex vert
                #pragma fragment frag

                //color of the outline
                fixed4 _OutlineColor;
            //thickness of the outline
                float _OutlineThickness;
                int _Outline;
            //the object data that's available to the vertex shader
            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            //the data that's used to generate fragments and can be read by the fragment shader
            struct v2f {
                float4 position : SV_POSITION;
            };

            //the vertex shader
            v2f vert(appdata v) {
                v2f o;
                //calculate the position of the expanded object
                float3 normal = normalize(v.normal);
                float3 outlineOffset = normal * _OutlineThickness;
                float3 position = v.vertex + outlineOffset;
                //convert the vertex positions from object space to clip space so they can be rendered
                o.position = UnityObjectToClipPos(position);

                return o;
            }

            //the fragment shader
            fixed4 frag(v2f i) : SV_TARGET{
                if(_Outline)
                {
                    return _OutlineColor;
                }
                else{
                    return fixed4(0.0,0.0,0.0,0.0);
                }
            }

            ENDCG
        }
    }
}
