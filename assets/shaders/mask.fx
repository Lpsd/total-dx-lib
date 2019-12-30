/* 
    Author: 50p 
    Version: v1.0 
    Description: This shader allows you to mask a texture with a mask texture (black and white). 
*/ 
  
  
texture ScreenTexture; 
sampler implicitInputTexture = sampler_state 
{ 
    Texture = <ScreenTexture>; 
}; 
  
texture MaskTexture; 
sampler implicitMaskTexture = sampler_state 
{ 
    Texture = <MaskTexture>; 
}; 
  
  
float4 MaskTextureMain( float2 uv : TEXCOORD0 ) : COLOR0 
{ 
     
    float4 sampledTexture = tex2D( implicitInputTexture, uv ); 
    float4 maskSampled = tex2D( implicitMaskTexture, uv ); 
    sampledTexture.a = (maskSampled.r + maskSampled.g + maskSampled.b) / 3.0f; 
    return sampledTexture; 
} 
  
technique Technique1 
{ 
    pass Pass1 
    { 
        AlphaBlendEnable = true; 
        SrcBlend = SrcAlpha; 
        DestBlend = InvSrcAlpha; 
        PixelShader = compile ps_2_0 MaskTextureMain(); 
    } 
} 