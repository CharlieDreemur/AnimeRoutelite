using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(Material))]
public class FaceMaterialEditor : MaterialEditor 
{
    public override void OnInspectorGUI()
    {
        // if we are not visible... return
        if (!isVisible)
            return;

        // Get the target material
        Material material = (Material)target;

        // Ensure we're working with the correct material
        if (material.shader.name != "Aloha/Anime_Face!!!!Shading")
        {
            // Render the default inspector
            base.OnInspectorGUI ();
            return;
        }

        // Group: Texture Settings
        GUILayout.Label("Texture Settings", EditorStyles.boldLabel);
        material.SetTexture("_MainTex", (Texture)EditorGUILayout.ObjectField("Texture", material.GetTexture("_MainTex"), typeof(Texture), false));

        // Group: Lighting Settings
        GUILayout.Label("Lighting Settings", EditorStyles.boldLabel);
        material.SetFloat("_LightSmooth", EditorGUILayout.Slider("Light Smooth", material.GetFloat("_LightSmooth"), 0f, 1f));
        material.SetFloat("_ShadowDarkness", EditorGUILayout.Slider("Shadow Darkness", material.GetFloat("_ShadowDarkness"), 0f, 1f));
        material.SetFloat("_ShadowDarkThreshold", EditorGUILayout.Slider("Shadow Darkness", material.GetFloat("_ShadowDarkness"), 0f, 1f));
        material.SetFloat("_ShadowLightThreshold", EditorGUILayout.Slider("Shadow Darkness", material.GetFloat("_ShadowDarkness"), 0f, 1f));

        // Group: Direction Vectors
        GUILayout.Label("Direction Vectors", EditorStyles.boldLabel);
        material.SetVector("_HeadFrontVector", EditorGUILayout.Vector3Field("Character Facing Vector", material.GetVector("_HeadFrontVector")));
        material.SetVector("_HeadRightVector", EditorGUILayout.Vector3Field("Character Right Vector", material.GetVector("_HeadRightVector")));
        material.SetVector("_HeadCenterPoint", EditorGUILayout.Vector3Field("Center Point of Head", material.GetVector("_HeadCenterPoint")));

        // Apply changes to the material
        if (GUI.changed)
        {
            EditorUtility.SetDirty(material);
        }
    }
}