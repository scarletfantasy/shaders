Shader "Unlit/mygauss"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        CGINCLUDE
        #pragma multi_compile_fog

        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float2 uv[5] : TEXCOORD0;
            UNITY_FOG_COORDS(1)
            float4 vertex : SV_POSITION;
        };

        sampler2D _MainTex;
        float4 _MainTex_ST;
        float _BlurSize;

        v2f vert_row (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            float2 uv = TRANSFORM_TEX(v.uv, _MainTex);
            o.uv[0]=uv;
            o.uv[1]=uv+float2(0.0,_MainTex_ST.x*1.0)*_BlurSize;
            o.uv[2]=uv+float2(0.0,_MainTex_ST.x*2.0)*_BlurSize;
            o.uv[3]=uv-float2(0.0,_MainTex_ST.x*1.0)*_BlurSize;
            o.uv[4]=uv-float2(0.0,_MainTex_ST.x*2.0)*_BlurSize;
            
            UNITY_TRANSFER_FOG(o,o.vertex);
            return o;
        }
        v2f vert_col (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            float2 uv = TRANSFORM_TEX(v.uv, _MainTex);
            o.uv[0]=uv;
            o.uv[1]=uv+float2(_MainTex_ST.y*1.0,0.0)*_BlurSize;
            o.uv[2]=uv+float2(_MainTex_ST.y*2.0,0.0)*_BlurSize;
            o.uv[3]=uv-float2(_MainTex_ST.y*1.0,0.0)*_BlurSize;
            o.uv[4]=uv-float2(_MainTex_ST.y*2.0,0.0)*_BlurSize;
            
            UNITY_TRANSFER_FOG(o,o.vertex);
            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            // sample the texture
            float3 sum=0;
            sum += tex2D(_MainTex, i.uv[0]).rgb*0.4026;
            sum += tex2D(_MainTex, i.uv[1]).rgb*0.2442;
            sum += tex2D(_MainTex, i.uv[2]).rgb*0.0545;
            sum += tex2D(_MainTex, i.uv[3]).rgb*0.2442;
            sum += tex2D(_MainTex, i.uv[4]).rgb*0.0545;

            fixed4 color=fixed4(sum,1.0)
            // apply fog
            UNITY_APPLY_FOG(i.fogCoord, color);
            return color;
        }
        ENDCG
        Pass
        {
            NAME "gaussrow"
            CGPROGRAM
            #pragma vertex vert_row
            #pragma fragment frag

            ENDCG
        }

        
        Pass
        {
            NAME "gausscol"
            CGPROGRAM
            #pragma vertex vert_col
            #pragma fragment frag

            ENDCG
        }
    }
    FallBack off
}
