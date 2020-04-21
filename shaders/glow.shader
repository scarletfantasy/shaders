

Shader "Unlit/glow"
{
    Properties {  
        _MainColor("Rim Color",COLOR) = (1,1,1,1)
        _Scale("Scale",range(1,8)) =2
        _Outer("Outer",range(0,1)) = 0.2
    }  
    SubShader {  
        Tags { "RenderType"="Opaque" "queue" = "Transparent"}  
        LOD 100 

        
        Pass {  
            blend srcalpha one
            zwrite off

            CGPROGRAM  
              
            #pragma vertex vert  
            #pragma fragment frag  
              
            #include "UnityCG.cginc"  
            

             float4 _MainColor;
             float _Scale;
             float _Outer;

            struct a2v {  
                float4 vertex : POSITION;  
                float3 normal : NORMAL;  
                float4 texcoord : TEXCOORD0;  
            };  
              
            struct v2f {  
                float4 pos : POSITION; 
                float3 normal:TEXCOORD0;
                float4 vertex:TEXCOORD1; 
            };  
              
            v2f vert(a2v v) {  
                v2f o;
                v.vertex.xyz += v.normal*_Outer;
                o.pos = UnityObjectToClipPos(v.vertex);  
                o.vertex = v.vertex;
                o.normal = v.normal;
                return o;  
            }  
              
            float4 frag(v2f i) : COLOR { 
                
                float3 N =  UnityObjectToWorldNormal(i.normal);
                float3 V =  normalize( WorldSpaceViewDir(i.vertex));
                float bright =pow(saturate(dot(N,V)),_Scale);

                _MainColor.a *= bright;

                return _MainColor;  

            }  
              
            ENDCG  
        }  

        
        Pass {  
            Tags { "LightMode" = "ForwardBase" }  


            
            blend srcalpha oneminussrcalpha
            zwrite off

            CGPROGRAM  
              
            #pragma vertex vert  
            #pragma fragment frag  
              
            #include "UnityCG.cginc"  
            

             float4 _MainColor;
             float _Scale;

            struct a2v {  
                float4 vertex : POSITION;  
                float3 normal : NORMAL;  
                float4 texcoord : TEXCOORD0;  
            };  
              
            struct v2f {  
                float4 pos : POSITION; 
                float3 normal:TEXCOORD0;
                float4 vertex:TEXCOORD1; 
            };  
              
            v2f vert(a2v v) {  
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);  

                o.vertex = v.vertex;
                o.normal = v.normal;
                return o;  
            }  
              
            float4 frag(v2f i) : COLOR { 
                
                float3 N =  UnityObjectToWorldNormal(i.normal);
                float3 V =  normalize( WorldSpaceViewDir(i.vertex));
                float bright =pow( 1.0 - saturate(dot(N,V)),_Scale);
                return _MainColor*  bright;  
            }  
              
            ENDCG  
        }  
    }   
    FallBack "Diffuse"  
}
