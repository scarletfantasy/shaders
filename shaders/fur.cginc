#ifndef MY_CG_INCLUDE
#define MY_CG_INCLUDE
#ifndef STEP
#define STEP 0.0f
#endif

#ifndef _WindSpeed
#define _WindSpeed 9.8f
#endif
#include "UnityCG.cginc"
#include  "UnityStandardBRDF.cginc"
struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
};

struct v2f
{
    float4 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
    float4 vertex : SV_POSITION;
    float3 normal : NORMAL;
};
float _FurLength, _FurAOInstensity=1.0f,_Thinkness=1.0f, _FurDensity=1.0f,_GravityStrength;
float3 _Gravity;
sampler2D _MainTex,_FurTex;
float4 _MainTex_ST;
inline v2f vert(appdata v)
{
    v2f o;
    _Gravity=float3(0.0f,-1.0f,0.0f);
    half3 direction = _Gravity * _GravityStrength + v.normal * (1 - _GravityStrength);
    direction=lerp(v.normal, direction, STEP);
    float3 newPos = v.vertex.xyz + direction * _FurLength * STEP;
    //float3 gravity = mul(unity_ObjectToWorld, _Gravity + sin(_WindSpeed * _Time.y) * _Wind);

    float k = pow(STEP, 3);
    newPos = newPos ;//+ gravity * k;
    o.vertex = UnityObjectToClipPos(float4(newPos, 1.0f));
                //加入毛发阴影，越是中心位置，阴影越明显，边缘位置阴影越浅
    float znormal = 1 - dot(v.normal, float3(0, 0, 1));
    o.uv.xy = v.uv;
    o.uv.zw = float2(znormal, znormal) * 0.001;
    o.normal = mul(v.normal, (float3x3) unity_WorldToObject);

    return o;
}

inline fixed4 frag(v2f i) : SV_Target
{
                // sample the texture
    fixed4 col = tex2D(_MainTex, TRANSFORM_TEX(i.uv.xy, _MainTex)) ;
    
    float alpha=1.0f-dot(float3(0.299, 0.587, 0.114),col.rgb);
    
    alpha=step(STEP*STEP,alpha);
    col.a=alpha*(1.0f-STEP);
    col.rgb=tex2D(_FurTex, i.uv.xy).rgb ;
                //增加毛发阴影，毛发越靠近根部的像素点颜色越暗
    /*col.rgb -= (pow(1 - STEP, 3)) * _FurAOInstensity;

    fixed3 lightDir = normalize(_WorldSpaceLightPos0);
              //_Thinkness 毛发细度，改变tile增强毛发细度
    float4 furCol = tex2D(_FurTex, i.uv.xy * _Thinkness);
    fixed4 ColOffset = tex2D(_FurTex, i.uv.xy * _Thinkness + i.uv.zw);
    float3 final = dot(float3(0.299, 0.587, 0.114), col.rgb - ColOffset.rgb);
    col.rgb -= final * _FurAOInstensity;

    fixed3 diffuse = _LightColor0.rgb * col.rgb * max(0, dot(normalize(i.normal), lightDir));

    fixed alpha = clamp(col.a * _FurDensity * (2 - STEP * 4), 0, 1);
    return float4(col.rgb + diffuse, alpha);*/
    return col;
    
    
}

#endif