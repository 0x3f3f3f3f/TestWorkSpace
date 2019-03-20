using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

#if UNITY_EDITOR
using UnityEditor;
using UnityEngine.Rendering.PostProcessing;
using UnityEditor.Rendering.PostProcessing;
#endif

[Serializable]
[UnityEngine.Rendering.PostProcessing.PostProcess(typeof(NotebookDrawingsRenderer), 
    PostProcessEvent.AfterStack, "VisualSketch/NotebookDrawings", false)]
public sealed class NotebookDrawings : PostProcessEffectSettings
{
    public Shader shader; // 无效？？？？？？
    public Texture noise; // 无效？？？？？？
    [Tooltip("Show Grid")]
    public BoolParameter Grid = new BoolParameter() { value = true };
}

public sealed class NotebookDrawingsRenderer : PostProcessEffectRenderer<NotebookDrawings>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("VisualSketch/Notebook Drawings2"));
        sheet.properties.SetFloat("_Grid", settings.Grid ? 1.0f : 0f);
        //sheet.properties.SetTexture("_NoiseTex", settings.noise);
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}

#if UNITY_EDITOR

[PostProcessEditor(typeof(NotebookDrawings))]
public sealed class NotebookDrawingsEditor : PostProcessEffectEditor<NotebookDrawings>
{
    SerializedProperty m_shader;
    SerializedProperty m_noise;
    SerializedParameterOverride m_Grid;

    public override void OnEnable()
    {
        m_shader = FindProperty(x => x.shader);
        m_noise = FindProperty(x => x.noise);
        m_Grid = FindParameterOverride(x => x.Grid);
    }

    public override void OnInspectorGUI()
    { 
        EditorGUILayout.PropertyField(m_shader);
        EditorGUILayout.PropertyField(m_noise);
        PropertyField(m_Grid);
    }
}

#endif