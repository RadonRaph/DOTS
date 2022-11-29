using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Raccoonlabs
{
    public static class RandomExtend
    {
        public static float RandomMinMax(float min, float max, bool signed = false)
        {
            float r = min / max;
            float result = UnityEngine.Random.Range(r, 1) * max;
            if (signed)
            {
                int sign = 1;
                if (UnityEngine.Random.value < 0.5f)
                {
                    sign = -1;
                }

                result *= sign;
            }

            return result;
        }
        


        public static T RandomOne<T>(this T[] array)
        {
            if (array.Length > 1)
                return array[UnityEngine.Random.Range(0, array.Length)];
            else if (array.Length > 0)
                return array[0];
            else
                return default(T);
        }

        public static T RandomOne<T>(this List<T> array)
        {
            if (array.Count > 1)
                return array[UnityEngine.Random.Range(0, array.Count)];
            else if (array.Count > 0)
                return array[0];
            else
                return default(T);
        }

        public static int RandomSign()
        {
            float v = UnityEngine.Random.Range(0, 100);
            if (v > 50)
                return 1;
            else
                return -1;
        }
        
        public static Vector3 RandomPoint(this Bounds b)
        {
            return b.min + Random.value * (b.max - b.min);
        }
    }
}
