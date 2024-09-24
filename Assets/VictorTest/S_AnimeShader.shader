Shader "Aloha/Anime_FaceShading"
{
    Properties
    {
        // Main texture of Face
        _MainTex ("Texture", 2D) = "white" {}

        // Shadow Color
        _ShadowDarkness ("Shadow Darkeness", Range(0, 1)) = 0.1

        // Shadow Threshold
        _LightSmooth ("Light Smooth", Range(0, 1)) = 0.1
        _ShadowDarkThreshold ("Dark Shadow Threshold", Range(0, 1)) = 0.33
        _ShadowLightThreshold ("Light Shadow Threshold", Range(0, 1)) = 0.66

        _HeadFrontVector ("Character Facing Vector", Vector) = (0, 0, 0)
        _HeadRightVector ("Character Right Vector", Vector) = (0, 0, 0)

        _HeadCenterPoint ("Center Point of Head", Vector) = (0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            // Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members facePosition)
            #pragma exclude_renderers d3d11
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                // System Variables
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float4 vertex : SV_POSITION;

                // Custom Variables
                float3 faceVector : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _LightSmooth;
            float _ShadowDarkness;

            float _ShadowDarkThreshold;
            float _ShadowLightThreshold;

            float4 _HeadFrontVector;
            float4 _HeadRightVector;
            float3 _HeadCenterPoint;

            fixed3 RGBtoHSV(fixed3 rgb)
            {
                // Calculate the maximum, minimum, and difference of the RGB components
                fixed cMax = max(rgb.r, max(rgb.g, rgb.b)); // Maximum of r, g, b
                fixed cMin = min(rgb.r, min(rgb.g, rgb.b)); // Minimum of r, g, b
                fixed delta = cMax - cMin;                  // Difference between max and min

                // Initialize HSV values
                fixed3 hsv = fixed3(0, 0, cMax);            // Hue, Saturation, Value

                // Calculate the Hue
                if (delta > 0.00001) // Prevent division by zero
                {
                    // Hue calculation based on which component is the maximum
                    if (cMax == rgb.r)
                    {
                        hsv.x = (rgb.g - rgb.b) / delta;    // Between yellow and magenta
                    }
                    else if (cMax == rgb.g)
                    {
                        hsv.x = 2.0 + (rgb.b - rgb.r) / delta; // Between cyan and yellow
                    }
                    else if (cMax == rgb.b)
                    {
                        hsv.x = 4.0 + (rgb.r - rgb.g) / delta; // Between magenta and cyan
                    }

                    hsv.x = frac(hsv.x / 6.0); // Hue value should be in [0, 1]
                }

                // Calculate the Saturation
                if (cMax > 0.0)
                {
                    hsv.y = delta / cMax; // Saturation
                }

                return hsv;
            }

            fixed3 HSVtoRGB(fixed3 hsv)
            {
                // Initialize output RGB
                fixed3 rgb = fixed3(0, 0, 0);

                // Unpack HSV values
                fixed h = hsv.x; // Hue
                fixed s = hsv.y; // Saturation
                fixed v = hsv.z; // Value

                // Calculate chroma, an intermediate value
                fixed c = v * s; 

                // Find the secondary color value based on hue
                fixed x = c * (1 - abs(fmod(h * 6, 2) - 1)); 

                // Adjust the RGB values based on which sector of the hue we are in
                if (0 <= h && h < 1.0 / 6.0)
                {
                    rgb = fixed3(c, x, 0);
                }
                else if (1.0 / 6.0 <= h && h < 2.0 / 6.0)
                {
                    rgb = fixed3(x, c, 0);
                }
                else if (2.0 / 6.0 <= h && h < 3.0 / 6.0)
                {
                    rgb = fixed3(0, c, x);
                }
                else if (3.0 / 6.0 <= h && h < 4.0 / 6.0)
                {
                    rgb = fixed3(0, x, c);
                }
                else if (4.0 / 6.0 <= h && h < 5.0 / 6.0)
                {
                    rgb = fixed3(x, 0, c);
                }
                else if (5.0 / 6.0 <= h && h <= 1.0)
                {
                    rgb = fixed3(c, 0, x);
                }

                // Add the minimum value component to match brightness (Value in HSV)
                fixed m = v - c;
                return rgb + m; 
            }
            

            v2f vert (appdata v)
            {
                v2f o;

                // System Variables setup
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = normalize(mul((float3x3)unity_WorldToObject, v.normal));   

                // Custome Variables setup
                o.faceVector = normalize(o.worldPos - _HeadCenterPoint.xyz);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                // Get Main Light Direction
                float3 mainLightDirection = normalize(_WorldSpaceLightPos0.xyz);

                // Face Shadow
                float3 headspace_z = normalize(_HeadFrontVector.xyz);
                float3 headspace_x = normalize(_HeadRightVector.xyz);
                float3 headspace_y = normalize(cross(headspace_z, headspace_x));

                float u = dot(-mainLightDirection.xyz, headspace_x.xyz);
                float v = dot(-mainLightDirection.xyz, headspace_y.xyz);
                float w = dot(-mainLightDirection.xyz, headspace_z.xyz);
                float3 light_headspace = float3(u, v, w);

                u = dot(i.faceVector, headspace_x.xyz);
                v = dot(i.faceVector, headspace_y.xyz);
                w = dot(i.faceVector, headspace_z.xyz);
                float3 faceVector_headspace = float3(u, v, w);
                float faceLuminosity = -dot(normalize(light_headspace.xz), faceVector_headspace.xz);

                // Get Shadow                
                float shadow = dot(mainLightDirection, i.worldNormal);
                float smooth = smoothstep(0, _LightSmooth, shadow);
                fixed3 tex_HSV = RGBtoHSV(col.rgb);
                tex_HSV = fixed3(tex_HSV.r, saturate(tex_HSV.y + _ShadowDarkness * 1.3f), saturate(tex_HSV.z - _ShadowDarkness));
                fixed4 col_shadow = fixed4(HSVtoRGB(tex_HSV.rgb), col.a);

                // Shadow Thresholding
                float shadowAlpha = faceLuminosity;
                if (shadowAlpha < _ShadowDarkThreshold) shadowAlpha = 0.0f;
                else if (shadowAlpha < _ShadowLightThreshold) shadowAlpha = 0.5f;
                else shadowAlpha = 1.0f;

                return lerp(col_shadow, col, shadowAlpha);
            }
            ENDCG
        }
    }
}
