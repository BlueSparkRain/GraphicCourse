Shader "Unlit/Base_Fin_Fur_NonGpuIns"
{
      Properties
    {
        _MainTex ("BaseMap", 2D) = "white" {}
        _FurTex ("FurTex", 2D) = "white" {}
      
         _FaceViewThresh("FaceView Thresh",Range(0,1))=0.5
         _FurDensity("FurDensity ",Range(10,40))=15
         _AlphaCutout("AlphaCutout ",Range(0,1))=0
        _FinJointNum("_FinJointNum",Int)=1
        _BaseMove("BaseMove",Vector)=(0,0,0,0)
        _FinLength("FinLength",Float)=0.5//发片总长度
        _MoveFactor("MoveFactor",Float)=1
        _FaceNormalFactor("FaceNormalFactor",Range(0,1))=0
        _FinRandomDirIntensity("FinRandomDirIntensity",Range(0,1))=0
        _WindFreq("WindFreq",Vector)=(1,1,1,1)
        _WindMove("WindMove",Vector)=(1,1,1,1)
        
        
    [Header(Tesselation)][Space]
    _TessMinDist("Tesselation Min Distance", Range(0.1, 50)) = 1.0
    _TessMaxDist("Tesselation Max Distance", Range(0.1, 50)) = 10.0
    _TessFactor("Tessellation Factor", Range(1, 20))=1
    _InsideTessFactorIntensity("Tessellation Factor", Range(1, 20))=1
    }
    SubShader
    {
        // 设置渲染队列和混合模式，确保透明度效果正确
        Tags { "RenderType"="Opacity" "RenderPipeline"="UniversalPipeline"}
        LOD 100 // 简单的LOD，通常在游戏中使用更复杂的LOD系统

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha 
            ZWrite On
            Cull off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma hull hull
            #pragma domain domain
            #pragma  geometry Geom

            // 引入URP Shader Library，提供常用函数和宏
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // 定义从C#传入的顶点属性
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0; 
                float3 normalOS : NORMAL;
                
            };

            // 定义从顶点着色器传递到片段着色器的数据
            struct Varyings
            {
                float4 positionCS : SV_POSITION; // 裁剪顶点位置
                float3 positionWS : TEXCOORD0;   // 世界顶点位置
                float3 normalWS : TEXCOORD1;     // 世界法线方向
                float2 uv : TEXCOORD2;           // UV坐标
                float2 finUv : TEXCOORD5; // 从根部到尖端的因子 (0=根, 1=尖)
                float3 finTangentWS : TEXCOORD6;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST; // 纹理的缩放平移 (由TRANSFORM_TEX自动使用)
                float4 _FurTex_ST; // 纹理的缩放平移 (由TRANSFORM_TEX自动使用)
                half _AlphaCutout; // Alpha裁剪阈值
            
                float _FaceViewThresh;//视角剔除
                float _FurDensity;//发片细节密度
                float _FinRandomDirIntensity;//发片法线随机强度
                float _FaceNormalFactor;//发片面法线方向偏移贡献
            
                int  _FinJointNum;//发片段数
                float4 _BaseMove;
                float _FinLength;//发片总长度
                float _MoveFactor;//发片移动强度
                float4 _WindMove;
                float4 _WindFreq;
                float _TessMinDist;
                float _TessMaxDist;
                float _TessFactor;
                float _InsideTessFactorIntensity;
            CBUFFER_END

            // 纹理和采样器
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_FurTex); SAMPLER(sampler_FurTex);

            inline float rand(float2 seed)
            {
                return frac(sin(dot(seed.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            inline float3 rand3(float2 seed)
            {
                return 2.0 * (float3(rand(seed * 1), rand(seed * 2), rand(seed * 3)) - 0.5);
            }

            struct HsConstantOutput
            {
                float fTessFactor[3]    : SV_TessFactor;//必须有的语义，定义补丁三条边的细分因子
                float fInsideTessFactor : SV_InsideTessFactor;//定义了补丁内部区域的细分因子。它控制了补丁内部的三角形网格的密度
                //PN_三角形
                float3 f3B210 : POS3;
                float3 f3B120 : POS4;
                float3 f3B021 : POS5;
                float3 f3B012 : POS6;
                float3 f3B102 : POS7;
                float3 f3B201 : POS8;
                float3 f3B111 : CENTER;
                float3 f3N110 : NORMAL3;
                float3 f3N011 : NORMAL4;
                float3 f3N101 : NORMAL5;
            };

    //主外壳着色器函数
    [domain("tri")]
    [partitioning("integer")]
    [outputtopology("triangle_cw")]
    [patchconstantfunc("hullConst")]
    [outputcontrolpoints(3)]
    Attributes hull(InputPatch<Attributes, 3> input, uint id : SV_OutputControlPointID)
    {
        return input[id];
    }
            
    //补丁常量函数
    HsConstantOutput hullConst(InputPatch<Attributes, 3> i)
    {
        HsConstantOutput o = (HsConstantOutput)0;

        
        o.fTessFactor[0] = o.fTessFactor[1] = o.fTessFactor[2] = _TessFactor;
        o.fInsideTessFactor = _InsideTessFactorIntensity;

        float3 f3B003 = i[2].positionOS.xyz;//P2=B003
        float3 f3B030 = i[1].positionOS.xyz;//P1=B030
        float3 f3B300 = i[0].positionOS.xyz;//P0=B300

        float3 f3N002 = i[2].normalOS;
        float3 f3N020 = i[1].normalOS;
        float3 f3N200 = i[0].normalOS;
        
        //P0-P1边控制点
        o.f3B210 = ((2.0 * f3B300) + f3B030 - (dot((f3B030 - f3B300), f3N200) * f3N200)) / 3.0;
        o.f3B120 = ((2.0 * f3B030) + f3B300 - (dot((f3B300 - f3B030), f3N020) * f3N020)) / 3.0;
        //P1-P2边控制点
        o.f3B021 = ((2.0 * f3B030) + f3B003 - (dot((f3B003 - f3B030), f3N020) * f3N020)) / 3.0;
        o.f3B012 = ((2.0 * f3B003) + f3B030 - (dot((f3B030 - f3B003), f3N002) * f3N002)) / 3.0;
        //P0-P2边控制点
        o.f3B102 = ((2.0 * f3B003) + f3B300 - (dot((f3B300 - f3B003), f3N002) * f3N002)) / 3.0;
        o.f3B201 = ((2.0 * f3B300) + f3B003 - (dot((f3B003 - f3B300), f3N200) * f3N200)) / 3.0;
        
        float3 f3E = (o.f3B210 + o.f3B120 + o.f3B021 + o.f3B012 + o.f3B102 + o.f3B201) / 6.0;
        float3 f3V = (f3B003 + f3B030 + f3B300) / 3.0;
        o.f3B111 = f3E + ((f3E - f3V) / 2.0);
    
        float fV12 = 2.0 * dot(f3B030 - f3B300, f3N200 + f3N020) / dot(f3B030 - f3B300, f3B030 - f3B300);
        float fV23 = 2.0 * dot(f3B003 - f3B030, f3N020 + f3N002) / dot(f3B003 - f3B030, f3B003 - f3B030);
        float fV31 = 2.0 * dot(f3B300 - f3B003, f3N002 + f3N200) / dot(f3B300 - f3B003, f3B300 - f3B003);
        o.f3N110 = normalize(f3N200 + f3N020 - fV12 * (f3B030 - f3B300));
        o.f3N011 = normalize(f3N020 + f3N002 - fV23 * (f3B003 - f3B030));
        o.f3N101 = normalize(f3N002 + f3N200 - fV31 * (f3B300 - f3B003));
        return o;
    }
            
      [domain("tri")]Attributes domain(
      HsConstantOutput hsConst, 
      const OutputPatch<Attributes, 3> i,
      float3 bary : SV_DomainLocation)
    {
          Attributes o = (Attributes)0;
      
          float fU = bary.x;
          float fV = bary.y;
          float fW = bary.z;
          float fUU = fU * fU;
          float fVV = fV * fV;
          float fWW = fW * fW;
          float fUU3 = fUU * 3.0f;
          float fVV3 = fVV * 3.0f;
          float fWW3 = fWW * 3.0f;
          
          o.positionOS = float4(
              i[0].positionOS.xyz * fWW * fW +
              i[1].positionOS.xyz * fUU * fU +
              i[2].positionOS.xyz * fVV * fV +
              hsConst.f3B210 * fWW3 * fU +
              hsConst.f3B120 * fW * fUU3 +
              hsConst.f3B201 * fWW3 * fV +
              hsConst.f3B021 * fUU3 * fV +
              hsConst.f3B102 * fW * fVV3 +
              hsConst.f3B012 * fU * fVV3 +
              hsConst.f3B111 * 6.0f * fW * fU * fV, 
              1.0);
          o.normalOS = normalize(
              i[0].normalOS * fWW +
              i[1].normalOS * fUU +
              i[2].normalOS * fVV +
              hsConst.f3N110 * fW * fU +
              hsConst.f3N011 * fU * fV +
              hsConst.f3N101 * fW * fV);
          o.uv = 
              i[0].uv * fW + 
              i[1].uv * fU + 
              i[2].uv * fV;
          return o;
    }
            
            // 顶点着色器
            Attributes Vert(Attributes input)
            {
                return input;
            }
            
            //向流中追加1个顶点
            void AppendFinVertex(
                 inout TriangleStream<Varyings> stream, 
                 float2 uv, 
                 float3 posOS, 
                 float3 normalOS, 
                 float2 finUv,
                 float3 finSideDirWS)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(posOS);
                output.positionCS = vertexInput.positionCS ;
                output.positionWS = vertexInput.positionWS;
        
                output.normalWS = TransformObjectToWorldNormal(normalOS);
                output.uv = uv;
                output.finUv = finUv;
                output.finTangentWS = SafeNormalize(cross(output.normalWS, finSideDirWS));
                
                stream.Append(output);
            }

            //向流中追加所有顶点
            void AppendFinVertices(
                  inout TriangleStream<Varyings> stream,
                  Attributes input0,//三角形顶点1
                  Attributes input1,//三角形顶点2
                  Attributes input2)//三角形顶点3
            {
                //在对象空间进行所有方向计算
                //将第一个顶点作为鳍边的起点
                //对边中点作为鳍边的终点
                float3  line_start=input0.positionOS;//鳍边起点
                float3 line1=input1.positionOS-input0.positionOS;
                float3 line2=input2.positionOS-input0.positionOS;
                float3  line_end=  input0.positionOS+ (line1+line2)/2;//鳍边终点
                
                float2 uv_start=TRANSFORM_TEX(input0.uv,_MainTex);
                float2 uv_end=(TRANSFORM_TEX(input1.uv,_MainTex)+TRANSFORM_TEX(input2.uv,_MainTex))/2;

                float uv_offset=length(uv_start);
                float uv_scale=length(uv_start-uv_end) * _FurDensity;

                float3 finDirOS=input0.normalOS;
                finDirOS+= rand3(input0.uv) *_FinRandomDirIntensity;
                finDirOS=normalize(finDirOS);//生长方向的单位向量
        
                //float3 finDirWS=TransformObjectToWorld(finDirOS);
                //float3 posWS=TransformObjectToWorld(line_start);

                float finStep = _FinLength / _FinJointNum;//每个分段有多长
                float3 finSideDir=normalize(line_end-line_start);//宽方向的单位向量
        
                float3 finSideDirWS = TransformObjectToWorldDir(finSideDir);

                //将风力在世界坐标下计算
                float3 posWS_root=TransformObjectToWorld(line_start);
                float3 windAngle = _Time.w * _WindFreq.xyz;//计算了风力动画的当前相位
                float3 windMoveWS = _WindMove.xyz * sin(windAngle + posWS_root * _WindMove.w);
                //将风力偏再移转到物体空间
                float3 windMoveOS=TransformWorldToObjectDir(windMoveWS);// 这里用 Dir 因为是相对位移

                
                [unroll]
                for (int j=0;j<2;++j)
                {
                    float3 finLine_startPos= line_start;
                    float3 finLine_endPos= line_end;
                    float uvX1=uv_offset;
                    float uvX2=uv_offset+uv_scale;
                    
                    [loop]
                    for (  int i=0;i<=_FinJointNum;++i)
                    {
                        float finFactor = (float) i / _FinJointNum;//描述 当前的毛发段在整个毛发片上的位置
                        float moveFactor = pow(_MoveFactor,abs(finFactor) );//描述 风力和基础摆动对毛发当前分段的影响强度
                        
                        float3 OffsetOS = SafeNormalize(finDirOS + (windMoveOS+_BaseMove) * moveFactor) * finStep;//根据毛发的当前进度 (finFactor)，将风力和基础偏移叠加到毛发的正常生长方向上，并计算出当前分段的实际位移
                        
                        finLine_startPos += OffsetOS;
                        finLine_endPos += OffsetOS;//得到一边的起点终点在世界空间的位置
                        
                        float3 dirOS03 = normalize(finLine_endPos - finLine_startPos);
                        float3 faceNormalOS=normalize( cross(dirOS03,OffsetOS));//发片的法线方向
                        if(j<1)//渲染正面
                        {
                            //拿发片面法线再对鳍的生长方向进行混合，得到最终生长方向
                            float3 finNormalOS = normalize(lerp(finDirOS, faceNormalOS, _FaceNormalFactor));
                            //向流中追加一条鳍边的起点
                            AppendFinVertex(stream, uv_start, finLine_startPos, finNormalOS, float2(uvX1, finFactor), finSideDirWS);
                            //向流中追加一条鳍边的终点
                            AppendFinVertex(stream, uv_end, finLine_endPos, finNormalOS, float2(uvX2, finFactor), finSideDirWS);
                        }
                        else//渲染反面
                        {
                            faceNormalOS*=-1;
                              //拿发片面法线再对鳍的生长方向进行混合，得到最终生长方向
                            float3 finNormalOS = normalize(lerp(finDirOS, faceNormalOS, _FaceNormalFactor));
                            //向流中追加一条鳍边的终点
                            AppendFinVertex(stream, uv_end, finLine_endPos, finNormalOS, float2(uvX2, finFactor), finSideDirWS);
                            //向流中追加一条鳍边的起点
                            AppendFinVertex(stream, uv_start, finLine_startPos, finNormalOS, float2(uvX1, finFactor), finSideDirWS);
                        }
                    }
                          stream.RestartStrip();
                }
            }
            
            inline float3 GetViewDirectionOS(float3 posOS)
            {
            float3 cameraOS = TransformWorldToObject(GetCameraPositionWS());
            return normalize(posOS - cameraOS);
            }
            
            [maxvertexcount(39)]
            void Geom(triangle Attributes input[3],inout TriangleStream<Varyings> stream)
            {
                //渲染原始几何体
                for (int i=0;i<3;++i)
                {
                    Varyings output=(Varyings)0;
                    //得到各个坐标系下顶点位置
                    VertexPositionInputs vertexInput=GetVertexPositionInputs(input[i].positionOS.xyz);
                    output.positionCS=vertexInput.positionCS;
                    output.positionWS=vertexInput.positionWS;
                    output.normalWS=TransformObjectToWorld( input[i].normalOS);
                    output.uv = TRANSFORM_TEX(input[i].uv, _MainTex);
                    output.finUv=float2(-1.0,-1.0);//标记为-1，是为了标记原始几何体的像素，直接跳过在frag中和渲染的毛发片剔除有关的操作
                    stream.Append(output);
                }
                stream.RestartStrip();
                //渲染毛发片（每个三角形图元内渲染一个发片）

                //计算出输入三角形的面法线和中心
                float3 line1=(input[1].positionOS-input[0].positionOS).xyz;
                float3 line2=(input[2].positionOS-input[0].positionOS).xyz;
                float3 normalOS=normalize(cross(line1,line2));//输入三角形的面法线
                float3 centerOS=(input[0].positionOS+input[1].positionOS+input[2].positionOS)/3;//三角形的重心
                //计算视线与面法线近似度，剔除大于一定角度的发片
                float3 viewDir=GetViewDirectionOS(centerOS);
                float eyeDotN=dot(viewDir,normalOS);
                if(abs(eyeDotN)>_FaceViewThresh) return;

                //流中追加所有顶点
                AppendFinVertices(stream,input[0],input[1],input[2]);
            }

            // 片段着色器
            half4 Frag(Varyings input) : SV_Target
            {
                // 从纹理图集采样颜色
                half4 furColor = SAMPLE_TEXTURE2D(_FurTex, sampler_FurTex, input.finUv);
                if (input.finUv.x >= 0.0 && furColor.a < _AlphaCutout) discard;
              
                half4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                // --- 基础颜色 (无光照，只显示纹理颜色) ---
                half4 finalColor =baseColor; 
                return finalColor;
            }
            ENDHLSL
        }
    }
}
