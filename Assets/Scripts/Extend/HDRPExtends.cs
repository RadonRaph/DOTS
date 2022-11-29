using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using UnityEngine;
using UnityEngine.Rendering;

public static class HDRPExtends
{

    public static void FadeWeight(this Volume v, float value, float time)
    {
        v.gameObject.GetComponent<MonoBehaviour>().StartCoroutine(_FadeWeight(v, value, time));
    }

    static IEnumerator _FadeWeight(Volume v, float value, float time)
    {
        float baseVal = v.weight;
        float bTime = time;

        while (time > 0)
        {
            v.weight = Mathf.Lerp(baseVal, value, 1 - (time / bTime));
            yield return new WaitForEndOfFrame();
            time -= Time.deltaTime;
        }
    }
}