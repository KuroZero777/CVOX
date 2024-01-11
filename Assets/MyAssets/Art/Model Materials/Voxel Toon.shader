// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "JT/Custom/Voxel_Toon"
{
	Properties
	{
		[Header(TEXTURE SETTING)]_DiffuseTexture("DiffuseTexture", 2D) = "white" {}
		[Header(SHADOW LIGHT SETTING)]_LighterColor("LighterColor", Color) = (1,1,1,0)
		_DarkerColor("DarkerColor", Color) = (0,0,0,0)
		[Header(FRESNEL SETTING)]_NormalOffset("NormalOffset", Range( 0 , 1)) = 0.01
		_MaxDistance("MaxDistance", Range( 0 , 1)) = 0.3
		_FresnelColor("FresnelColor", Color) = (1,1,1,1)
		_FresnelBias("FresnelBias", Range( 0 , 1)) = 0
		_FresnelScale("FresnelScale", Range( 0 , 10)) = 1
		_FresnelPower("FresnelPower", Range( 0 , 10)) = 5
		[Header(TRIPLANER SETTING)]_T_Triplaner("T_Triplaner", 2D) = "white" {}
		_T_Tile("T_Tile", Float) = 1
		_T_Lerp("T_Lerp", Range( 0 , 1)) = 0.5
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityCG.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
			float eyeDepth;
		};

		uniform float4 _DarkerColor;
		uniform sampler2D _DiffuseTexture;
		uniform float4 _DiffuseTexture_ST;
		uniform float4 _LighterColor;
		uniform sampler2D _T_Triplaner;
		uniform float _T_Tile;
		uniform float _T_Lerp;
		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
		uniform float4 _CameraDepthTexture_TexelSize;
		uniform float _NormalOffset;
		uniform float _MaxDistance;
		uniform float4 _FresnelColor;
		uniform float _FresnelBias;
		uniform float _FresnelScale;
		uniform float _FresnelPower;


		inline float4 TriplanarSampling87( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = tex2D( topTexMap, tiling * worldPos.zy * float2(  nsign.x, 1.0 ) );
			yNorm = tex2D( topTexMap, tiling * worldPos.xz * float2(  nsign.y, 1.0 ) );
			zNorm = tex2D( topTexMap, tiling * worldPos.xy * float2( -nsign.z, 1.0 ) );
			return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			o.eyeDepth = -UnityObjectToViewPos( v.vertex.xyz ).z;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			o.Normal = float3(0,0,1);
			float2 uv_DiffuseTexture = i.uv_texcoord * _DiffuseTexture_ST.xy + _DiffuseTexture_ST.zw;
			float4 tex2DNode52 = tex2D( _DiffuseTexture, uv_DiffuseTexture );
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult61 = dot( ase_worldViewDir , ase_worldlightDir );
			float4 temp_output_55_0 = ( ( _DarkerColor * ( tex2DNode52 * saturate( -dotResult61 ) ) ) + ( ( tex2DNode52 * saturate( ( 1.0 - -dotResult61 ) ) ) * _LighterColor ) );
			o.Albedo = temp_output_55_0.rgb;
			float2 temp_cast_1 = (_T_Tile).xx;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_vertex3Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float3 ase_vertexNormal = mul( unity_WorldToObject, float4( ase_worldNormal, 0 ) );
			ase_vertexNormal = normalize( ase_vertexNormal );
			float4 triplanar87 = TriplanarSampling87( _T_Triplaner, ase_vertex3Pos, ase_vertexNormal, 1.0, temp_cast_1, 1.0, 0 );
			float4 color91 = IsGammaSpace() ? float4(1,1,1,0) : float4(1,1,1,0);
			float4 lerpResult93 = lerp( triplanar87 , color91 , _T_Lerp);
			float3 objToViewDir3 = mul( UNITY_MATRIX_IT_MV, float4( ase_vertexNormal, 0 ) ).xyz;
			float2 appendResult5 = (float2(objToViewDir3.xy));
			float3 objToView7 = mul( UNITY_MATRIX_MV, float4( ase_vertex3Pos, 1 ) ).xyz;
			float2 appendResult8 = (float2(objToView7.xy));
			float3 appendResult11 = (float3(( ( _NormalOffset * appendResult5 ) + appendResult8 ) , objToView7.z));
			float4 appendResult13 = (float4(appendResult11 , 1.0));
			float4 computeScreenPos16 = ComputeScreenPos( mul( UNITY_MATRIX_P, appendResult13 ) );
			computeScreenPos16 = computeScreenPos16 / computeScreenPos16.w;
			computeScreenPos16.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos16.z : computeScreenPos16.z* 0.5 + 0.5;
			float eyeDepth18 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, computeScreenPos16.xy ));
			float MaxDistance19 = _MaxDistance;
			float3 appendResult26 = (float3(_FresnelColor.rgb));
			float fresnelNdotV28 = dot( ase_worldNormal, ase_worldViewDir );
			float fresnelNode28 = ( _FresnelBias + _FresnelScale * pow( 1.0 - fresnelNdotV28, _FresnelPower ) );
			o.Emission = ( lerpResult93 * ( float4( ( (0.0 + (min( ( eyeDepth18 - i.eyeDepth ) , MaxDistance19 ) - 0.0) * (1.0 - 0.0) / (MaxDistance19 - 0.0)) * ( appendResult26 * fresnelNode28 ) ) , 0.0 ) + temp_output_55_0 ) ).rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows noshadow vertex:vertexDataFunc 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float3 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.customPack1.z = customInputData.eyeDepth;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				surfIN.eyeDepth = IN.customPack1.z;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.CommentaryNode;1;-4025.281,-1518.599;Inherit;False;2979.283;1225.883;Depth Rim;36;39;38;37;36;35;34;33;32;31;28;27;26;25;24;23;22;21;20;19;18;17;16;15;14;13;12;11;10;9;8;7;6;5;4;3;2;Depth Rim;1,1,1,1;0;0
Node;AmplifyShaderEditor.NormalVertexDataNode;2;-3933.904,-1155.671;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TransformDirectionNode;3;-3694.704,-1150.471;Inherit;False;Object;View;False;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.PosVertexDataNode;4;-3990.929,-948.5356;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;5;-3462.557,-1141.431;Inherit;False;FLOAT2;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-3584.276,-1282.691;Inherit;False;Property;_NormalOffset;NormalOffset;6;1;[Header];Create;True;1;FRESNEL SETTING;0;0;False;0;False;0.01;0.024;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;7;-3726.993,-927.094;Inherit;False;Object;View;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;8;-3446.885,-985.1064;Inherit;False;FLOAT2;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;9;-3246.702,-1218.562;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;10;-3157.943,-1067.957;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;11;-3030.403,-968.4466;Inherit;False;FLOAT3;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ProjectionMatrixNode;12;-2908.832,-1205.785;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.DynamicAppendNode;13;-2872.621,-1076.874;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;14;-2713.292,-1198.542;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;15;-2220.835,-1430.942;Inherit;False;Property;_MaxDistance;MaxDistance;7;0;Create;True;0;0;0;False;0;False;0.3;0.274;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ComputeScreenPosHlpNode;16;-2487.513,-1064.713;Inherit;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SurfaceDepthNode;17;-2221.557,-1296.661;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;18;-2220.286,-1066.279;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;19;-1954.834,-1427.042;Inherit;False;MaxDistance;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-2119.593,-575.2373;Inherit;False;Property;_FresnelBias;FresnelBias;9;0;Create;True;0;0;0;False;0;False;0;0.466;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;21;-1874.264,-1069.944;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;22;-2142.184,-494.3856;Inherit;False;Property;_FresnelScale;FresnelScale;10;0;Create;True;0;0;0;False;0;False;1;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;23;-1947.651,-877.1429;Inherit;False;19;MaxDistance;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;24;-2158.83,-406.3999;Inherit;False;Property;_FresnelPower;FresnelPower;11;0;Create;True;0;0;0;False;0;False;5;9.79;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;25;-2035.174,-750.0196;Inherit;False;Property;_FresnelColor;FresnelColor;8;0;Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;26;-1710.578,-678.68;Inherit;False;FLOAT3;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMinOpNode;27;-1717.311,-930.3777;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;28;-1793.803,-560.4774;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;29;-2685.134,-268.0346;Inherit;False;1648.59;816.6406;Toon;15;66;65;64;63;62;61;60;59;58;57;56;55;54;53;30;Toon;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;30;-2322.53,-205.7486;Inherit;False;570.5925;275.2207;Main Texture;2;52;51;Main Texture;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-1497.749,-669.1681;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TFHCRemapNode;32;-1528.765,-898.9983;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;34;-2726.287,-858.6682;Inherit;False;View;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;35;-1303.898,-1134.425;Inherit;False;38;DebugEyeDepth;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GammaToLinearNode;36;-1811.6,-1189.221;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;37;-1583.3,-1269.274;Inherit;False;Property;_DebugEyeDepth;DebugEyeDepth;5;0;Create;True;0;0;0;False;0;False;0;0;0;True;;KeywordEnum;2;Surf;DepthTexture;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;38;-1312.909,-1269.937;Inherit;False;DebugEyeDepth;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GammaToLinearNode;39;-1803.094,-1327.345;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;51;-2288.556,-142.4819;Inherit;True;Property;_DiffuseTexture;DiffuseTexture;0;1;[Header];Create;True;1;TEXTURE SETTING;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;52;-2046.577,-142.9313;Inherit;True;Property;_TextureSample1;Texture Sample 1;13;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;53;-1604.795,59.3222;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;-1608.244,212.7766;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;55;-1168.245,192.7766;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;56;-1366.406,-1.465988;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0.5,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;57;-1393.542,275.9753;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0.5,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;58;-1616.304,-179.6655;Inherit;False;Property;_DarkerColor;DarkerColor;4;0;Create;True;0;0;0;False;0;False;0,0,0,0;0.2358491,0.2347366,0.2347366,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;59;-1616.335,348.1677;Inherit;False;Property;_LighterColor;LighterColor;3;1;[Header];Create;True;1;SHADOW LIGHT SETTING;0;0;False;0;False;1,1,1,0;0.8679245,0.8679245,0.8679245,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;60;-2654.445,157.1119;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;61;-2418.272,113.4039;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;62;-2172.478,114.6221;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;63;-1961.355,419.1466;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;64;-1977.447,115.8469;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;65;-1803.354,418.1466;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;66;-2638.344,-23.02798;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;67;-1598.449,582.0368;Inherit;False;564.1846;339.3009;Outline;3;97;89;68;Outline;1,1,1,1;0;0
Node;AmplifyShaderEditor.ColorNode;68;-1504.595,630.1606;Inherit;False;Property;_OutlineColor;OutlineColor;1;1;[Header];Create;True;1;OUTLINE SETTINGS;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TriplanarNode;87;-326.8247,-713.4124;Inherit;True;Spherical;Object;False;Top Texture 0;_TopTexture0;white;-1;None;Mid Texture 0;_MidTexture0;white;1;None;Bot Texture 0;_BotTexture0;white;0;None;Triplanar Sampler;Tangent;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;89;-1567.212,817.8181;Inherit;False;Property;_OutlineWidth;OutlineWidth;2;0;Create;True;0;0;0;False;0;False;0;0.009;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;90;-937.4557,-246.2396;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;91;-175.8516,-516.8132;Inherit;False;Constant;_T_Color;T_Color;26;0;Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;92;-236.8186,-339.5192;Inherit;False;Property;_T_Lerp;T_Lerp;14;0;Create;True;0;0;0;False;0;False;0.5;0.769;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;93;68.9043,-539.3207;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;94;-410.2908,-354.7122;Inherit;False;Property;_T_Tile;T_Tile;13;0;Create;True;0;0;0;False;0;False;1;4.14;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;96;315.2583,-270.958;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.OutlineNode;97;-1271.316,753.2267;Inherit;False;0;True;None;0;0;Front;True;True;True;True;0;False;;3;0;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;115;-729.7103,-92.63568;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;113;593.6953,-189.0992;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;JT/Custom/Voxel_Toon;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;False;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.TexturePropertyNode;95;-578.4846,-790.9918;Inherit;True;Property;_T_Triplaner;T_Triplaner;12;1;[Header];Create;True;1;TRIPLANER SETTING;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;-1314.427,-774.8201;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
WireConnection;3;0;2;0
WireConnection;5;0;3;0
WireConnection;7;0;4;0
WireConnection;8;0;7;0
WireConnection;9;0;6;0
WireConnection;9;1;5;0
WireConnection;10;0;9;0
WireConnection;10;1;8;0
WireConnection;11;0;10;0
WireConnection;11;2;7;3
WireConnection;13;0;11;0
WireConnection;14;0;12;0
WireConnection;14;1;13;0
WireConnection;16;0;14;0
WireConnection;18;0;16;0
WireConnection;19;0;15;0
WireConnection;21;0;18;0
WireConnection;21;1;17;0
WireConnection;26;0;25;0
WireConnection;27;0;21;0
WireConnection;27;1;23;0
WireConnection;28;1;20;0
WireConnection;28;2;22;0
WireConnection;28;3;24;0
WireConnection;31;0;26;0
WireConnection;31;1;28;0
WireConnection;32;0;27;0
WireConnection;32;2;23;0
WireConnection;34;0;11;0
WireConnection;36;0;18;0
WireConnection;37;1;39;0
WireConnection;37;0;36;0
WireConnection;38;0;37;0
WireConnection;39;0;17;0
WireConnection;52;0;51;0
WireConnection;53;0;52;0
WireConnection;53;1;64;0
WireConnection;54;0;52;0
WireConnection;54;1;65;0
WireConnection;55;0;56;0
WireConnection;55;1;57;0
WireConnection;56;0;58;0
WireConnection;56;1;53;0
WireConnection;57;0;54;0
WireConnection;57;1;59;0
WireConnection;61;0;66;0
WireConnection;61;1;60;0
WireConnection;62;0;61;0
WireConnection;63;0;62;0
WireConnection;64;0;62;0
WireConnection;65;0;63;0
WireConnection;87;0;95;0
WireConnection;87;3;94;0
WireConnection;90;0;33;0
WireConnection;90;1;55;0
WireConnection;93;0;87;0
WireConnection;93;1;91;0
WireConnection;93;2;92;0
WireConnection;96;0;93;0
WireConnection;96;1;90;0
WireConnection;97;0;68;0
WireConnection;97;1;89;0
WireConnection;115;0;55;0
WireConnection;113;0;115;0
WireConnection;113;2;96;0
WireConnection;33;0;32;0
WireConnection;33;1;31;0
ASEEND*/
//CHKSM=618D56A0F6B776E409726FBD16318C8A7E31318F