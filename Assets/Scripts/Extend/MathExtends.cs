using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Raccoonlabs
{
    public static class MathExtends
    {
        public static float Remap(float value, float from1, float to1, float from2, float to2)
        {
            return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
        }

        public static float Posterize(float val,  float steps)
        {
            return Mathf.Round(val / steps);
        }

        public static int toInt(this bool b)
        {
            if (b == true)
            {
                return 1;
            }
            else
            {
                return 0;
            }
        }

        public static bool toBool(this int i)
        {
            if (i >= 1)
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        public static bool isIn(this float i, float min, float max)
        {
            return (i > min && i < max);
        }

        public static bool isIn(this float i, Vector2 range)
        {
            return (i > range.x && i < range.y);
        }

        public static void LookAtLock(this Transform t, Vector3 target, bool lockX, bool lockY, bool lockZ)
        {
            Vector3 _lock = t.eulerAngles;
            t.LookAt(target);
            Vector3 axis = t.eulerAngles;

            if (!lockX)
                _lock.x = axis.x;
            if (!lockY)
                _lock.y = axis.y;
            if (!lockZ)
                _lock.z = axis.z;


            t.eulerAngles = _lock;
        }

        public static Vector3Int ToV3IntCeiled(this Vector3 v)
        {
            return new Vector3Int(Mathf.CeilToInt(v.x), Mathf.CeilToInt(v.y), Mathf.CeilToInt(v.z));
        }

    }

}
