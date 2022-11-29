using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Raccoonlabs
{
    public static class AudioExtends 
    {
        public static void BlendVolume(this AudioSource a, float Volume, float delay)
        {
            a.GetComponentInParent<MonoBehaviour>().StartCoroutine(_BlendVolume(a, Volume, delay));
        }


        static IEnumerator _BlendVolume(AudioSource source, float volume, float t)
        {
            float initVolume = source.volume;
            float baseT = t;

            while (t > 0)
            {
                t -= Time.deltaTime;
                yield return new WaitForEndOfFrame();
                source.volume = Mathf.Lerp(initVolume, volume, (baseT - t) / baseT);
            }
        }

        public static void StartRandom(this AudioSource source)
        {
            source.Play();
            source.time = UnityEngine.Random.Range(0f, source.clip.length);
        }

        public static float PercentToDb(float percent)
        {
            float db = -((percent * percent) / 375f) + ((16 * percent) / 15) - 80;
            return db;
        }
    }
}
