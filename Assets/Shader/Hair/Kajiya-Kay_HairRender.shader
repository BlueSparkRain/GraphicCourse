Shader "Unlit/HairMaterial"
{
    //迪士尼改善版
    Properties
    {
        _MainTex ("DiffuseTex", 2D) = "white" {}
        _AlbedoConstruct("HairConstruct",Range(0,10))=2
        _LambertLitness("Litness",Range(0,3))=1
        _BumpTex ("BumpTex", 2D) = "white" {}
        _BumpScale("BumpScale",Range(0,5))= 1
        _SpecularShiftTex("SpeculatShiftTexture",2D)="white"{}
        _ShiftIntensity("ShiftIntensity", Range(0, 5)) = 1
        [HDR]_MainColor("MainColor",Color)=(1,1,1,1)
        _HairStyle("HairStyle",Range(0,300))=50
        _Tilling_Offset("Tilling & Offset",Vector)=(1,1,1,1)
        _SpecularMask("SpecularMaskTex",2D)="white"{}
        _AlphaTex("AlphaTex",2D)="white"{}
        _AlphaPow("AlphaPow",Range(0.5,5))= 1
        
        
        _SecondOffset("offset",Range(-2,2))=0.5
        
        [HDR]_SpecColor1 ("SpecColor 1", Color) = (1,1,1,1)
        _Gloss1("Gloss 1", Range(1, 256)) = 32
		_Specular1("Specular 1", Range(0, 2)) = 0.5
        
        [HDR]_SpecColor2 ("SpecColor 2", Color) = (1,1,1,1)
        _Gloss2("Gloss 2", Range(1, 256)) = 64
		_Specular2("Specular 2", Range(0, 2)) = 0.3
        
        
    }
    SubShader
    {
        LOD 100
        
        Pass
        {
            Tags { "RenderType"="Transparent" "LightingMode"="ForwardBase"}
            Cull off
            ZWrite on
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            
            sampler2D _MainTex;
            sampler2D _BumpTex;
            sampler2D _SpecularShiftTex;
            fixed4 _MainColor;
            float4 _MainTex_ST;
            float4 _BumpTex_ST;
            float _BumpScale;

            float4 _Tilling_Offset;
            float _LambertLitness;
            float _AlbedoConstruct;
            sampler2D _SpecularMask;
            float _SecondOffset;
            fixed4 _SpecColor2;
            fixed4 _SpecColor1;
            sampler2D _AlphaTex;
            float _AlphaPow;

            
            float _Gloss1;
			float _Specular1;

            float _Gloss2;
			float _Specular2;
            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;//xy记录纹理-zw记录法线 缩放偏移信息
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
                uint id:SV_VertexID;
                
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 wPos:TEXCOORD1;
                float3 wBitangent:TEXCOORD2;

                //切线空间到世界空间的 变换矩阵的3行
                float3 TtoW0:TEXCOORD3;
                float3 TtoW1:TEXCOORD4;
                float3 TtoW2:TEXCOORD5;
            };

            fixed3 GetLambertMode(fixed3 albedoColor,fixed3 worldNormal)
            {
                fixed3 lightDir=normalize(_WorldSpaceLightPos0);
                fixed3 baseColor=_LightColor0 * max(0,dot(worldNormal,lightDir));
                baseColor= (baseColor/2+_LambertLitness)*albedoColor;
                return  baseColor ;

            }
            
            fixed3 GetKajiyaSpecularMode(fixed3 albedoColor,fixed3 bitangent,fixed3 viewDir,fixed exponent,float strength)
            {
                //计算光照方向
                fixed3 lightDir=normalize(_WorldSpaceLightPos0);
                //计算半角向量
                fixed3 halfDir=normalize(lightDir+viewDir);
                //计算高光角度
                float dotTH= dot(halfDir,bitangent);
                float sinTH=sqrt(1-pow(dotTH,2));

                //计算高光颜色
                float dirAtten = smoothstep(-1.0, 0.0, dotTH);

                fixed3 specularColor= albedoColor* dirAtten*pow(sinTH,exponent)*strength;
                return  specularColor;
                
            }

            fixed3 ShiftTangent(fixed3 bitangent,fixed3 wnormal,float shiftValue)
            {
                fixed3 shiftTan=bitangent+wnormal*shiftValue;
                return normalize(shiftTan);
            }

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                //计算纹理缩放及偏移
                o.uv = v.uv * _Tilling_Offset.xy + _Tilling_Offset.zw;
                
                float3 wNormal=UnityObjectToWorldNormal(v.normal);
                float3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
                o.wPos= mul(v.vertex,UNITY_MATRIX_M);
                o.wBitangent=cross(wNormal,wTangent) * v.tangent.w;
                
                //切线空间（世界）
                o.TtoW0= float3(wTangent.x, o.wBitangent.x,wNormal.x);
                o.TtoW1= float3(wTangent.y, o.wBitangent.y,wNormal.y);
                o.TtoW2= float3(wTangent.z, o.wBitangent.z,wNormal.z);
                return o;
            }
            float _ShiftIntensity;
            fixed4 frag (Varyings i) : SV_Target
            {
                // 采样纹理
                fixed4 albedoColor = tex2D(_MainTex, i.uv);
                albedoColor= saturate( pow(albedoColor,_AlbedoConstruct));
                albedoColor=albedoColor *_MainColor;
                
                fixed4 bumpColor=tex2D(_BumpTex,i.uv);
                
                fixed3 tanNormal = UnpackNormal(bumpColor);
                //将法线贴图存储的法线信息转到切线空间（放缩校对）后转回世界空间
                tanNormal.xy *= _BumpScale;
                tanNormal.z= sqrt(1-saturate( dot(tanNormal.xy,tanNormal.xy)));
                float3 wNormal =float3(dot( i.TtoW0,tanNormal),dot( i.TtoW1,tanNormal),dot( i.TtoW2,tanNormal));

                float wnormal=float3(i.TtoW0.z,i.TtoW1.z,i.TtoW2.z);
                //计算漫反射颜色
                float3 lambertColor=GetLambertMode(albedoColor,wNormal);


                //根据偏移贴图偏移顶点切线
                float shiftValue=(tex2D(_SpecularShiftTex,i.uv)-0.5)*_ShiftIntensity;
                float3 shiftBitangent1=ShiftTangent(i.wBitangent,wNormal,0.2+shiftValue);
                float3 shiftBitangent2=ShiftTangent(i.wBitangent,wNormal,_SecondOffset+shiftValue);
                ////视线方向
                float3 viewDir=normalize(UnityWorldSpaceViewDir(i.wPos));
                //计算高光颜色
                float4 specularColor=fixed4(GetKajiyaSpecularMode(albedoColor,shiftBitangent1,viewDir,_Gloss1,_Specular1)*_SpecColor1,1);
                //计算最终颜色
                float3 finalColor=UNITY_LIGHTMODEL_AMBIENT+ lambertColor + specularColor;

                fixed4 endColor=fixed4(finalColor,1);
                float specularMask=tex2D(_SpecularMask,i.uv);
                endColor += specularMask*fixed4(GetKajiyaSpecularMode(albedoColor,shiftBitangent2,viewDir,_Gloss2,_Specular2)*_SpecColor2,0.1f); 
                //return fixed4(endColor.xyz, tex2D(_AlphaTex,i.uv).a);

                float alpha=pow(tex2D(_AlphaTex,i.uv).a,_AlphaPow);
                
                return fixed4(endColor.xyz, alpha);
                //return fixed4(alpha.xxxx);
                
            }
            ENDCG
        }

    }
}
