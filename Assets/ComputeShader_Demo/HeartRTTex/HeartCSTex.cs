using System;
using UnityEngine;

[ExecuteAlways]
public class HeartCSTex : MonoBehaviour
{
   public ComputeShader cs;
   public Material mat;
   public int size=512;
   public float heartScale_x=1;
   public float heartScale_y=1;
   public float yScaleBound=0.3f;
   public float animSpeed=1f;
   public float heartRim=1f;
   [Range(-1,1)]public float heartRimThread=1;
   int kernel;
   private RenderTexture rt;
   void Start()
   {
      kernel = cs.FindKernel("CSMain");
      rt = new RenderTexture(size, size, 0);
      rt.enableRandomWrite = true;  
      rt.Create();   
      //cs对rt进行计算
      cs.SetTexture(kernel, "Result", rt); 
      
      mat.SetTexture("_MainTex", rt);
      
   }
   
   private void Update()
   {
      rt = new RenderTexture(size, size, 0);
      cs.SetFloat("_TextureWidth",size);
      cs.SetFloat("_TextureHeight",size);
      cs.SetFloat("_HeartScale_X",heartScale_x);
      cs.SetFloat("_HeartScale_Y",heartScale_y);
      cs.SetFloat("_Time",Time.time*animSpeed);
      cs.SetFloat("_YScaleBound",yScaleBound);
      cs.SetFloat("_HeartRimThread",heartRimThread);
      cs.SetFloat("_HeartRim",heartRim);
      rt.enableRandomWrite = true;  
      rt.Create();
      cs.SetTexture(kernel, "Result", rt); 
      
      mat.SetTexture("_MainTex", rt);
      cs.Dispatch(kernel,   size/8, size/8,1);
   }
}
