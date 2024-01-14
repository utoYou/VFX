#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using log4net.Layout;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

public class GlowShaderMaterialInspector : ShaderGUI
{
    private Material _targetMat;
    private MaterialEditor _materialEditor;
    private MaterialProperty[] _materialProperties;
    private GUIStyle _propertiesStyle, _bigLabelStyle, _smallLabelStyle, _toggleButtonStyle;
    private int _bigFontSize = 16, _smallFontSize = 11;
    private string[] _oldKeywords;
    private string[] _oldKeyWords;
    private Material _originalMaterialCopy;
    private bool[] _currEnableDrawers;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        _materialEditor = materialEditor;
        _materialProperties = properties;
        _targetMat = materialEditor.target as Material;
        _oldKeywords = _targetMat.shaderKeywords;
        _propertiesStyle = new GUIStyle(EditorStyles.helpBox);
        _propertiesStyle.margin = new RectOffset(0, 0, 0, 0);
        _bigLabelStyle = new GUIStyle(EditorStyles.boldLabel);
        _bigLabelStyle.fontSize = _bigFontSize;
        _smallLabelStyle = new GUIStyle(EditorStyles.boldLabel);
        _smallLabelStyle.fontSize = _smallFontSize;
        _toggleButtonStyle = new GUIStyle(GUI.skin.button) { alignment = TextAnchor.MiddleCenter, richText = true };

        DrawProperty(0);
        Glow("Glow", "GLOW_ON");
    }

    private void Glow(string inspector, string keyword)
    {
        GUIContent effectNameLabel = new GUIContent();
        effectNameLabel.tooltip = keyword + " (C#)";
        
        EditorGUILayout.BeginVertical(_propertiesStyle);
        {
            bool useGlowTex = DrawEffectSubKeywordToggle("Use Glow Texture?", "GLOWTEX_ON");
            if (useGlowTex) DrawProperty(1);

            DrawProperty(2);
            DrawProperty(3);
            DrawProperty(4, true);
        }
        EditorGUILayout.EndVertical();
    }

    private void DrawProperty(int index, bool noReset = false)
    {
        MaterialProperty targetProperty = _materialProperties[index];

        EditorGUILayout.BeginHorizontal();
        {
            GUIContent propertyLabel = new GUIContent();
            propertyLabel.text = targetProperty.displayName;
            propertyLabel.tooltip = targetProperty.name + " (C#)";
            
            _materialEditor.ShaderProperty(targetProperty, propertyLabel);

            if (!noReset)
            {
                GUIContent resetButtonLabel = new GUIContent();
                resetButtonLabel.text = "R";
                resetButtonLabel.tooltip = "Resets to default value";
                if (GUILayout.Button(resetButtonLabel, GUILayout.Width(20))) ResetProperty(targetProperty);
            }
        }
        EditorGUILayout.EndHorizontal();
    }

    private void ResetProperty(MaterialProperty targetProperty)
    {
        if (_originalMaterialCopy == null) _originalMaterialCopy = new Material(_targetMat.shader);
        if (targetProperty.type == MaterialProperty.PropType.Float ||
            targetProperty.type == MaterialProperty.PropType.Range)
        {
            targetProperty.floatValue = _originalMaterialCopy.GetFloat(targetProperty.name);
        }
        else if (targetProperty.type == MaterialProperty.PropType.Vector)
        {
            targetProperty.vectorValue = _originalMaterialCopy.GetVector(targetProperty.name);
        }
        else if (targetProperty.type == MaterialProperty.PropType.Color)
        {
            targetProperty.colorValue = _originalMaterialCopy.GetColor(targetProperty.name);
        }
        else if (targetProperty.type == MaterialProperty.PropType.Texture)
        {
            targetProperty.textureValue = _originalMaterialCopy.GetTexture(targetProperty.name);
        }
    }

    private bool DrawEffectSubKeywordToggle(string inspector, string keyword, bool setCustomConfigAfter = false)
    {
        GUIContent propertyLabel = new GUIContent();
        propertyLabel.text = inspector;
        propertyLabel.tooltip = keyword + " (C#)";
        
        var toggle = _oldKeywords.Contains(keyword);
        bool ini = toggle;
        toggle = GUILayout.Toggle(toggle, propertyLabel);
        if (ini != toggle)
        {
            if (toggle) 
                _targetMat.EnableKeyword(keyword);
            else
                _targetMat.DisableKeyword(keyword);
        }
        return toggle;
    }
}
#endif