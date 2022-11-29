using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Raccoonlabs
{
    public static class VectorsExtends 
    {
        //VECTORS
        public static Vector2 ToVector2XY(this Vector3 v)
        {

            ///<summary>
            ///<para>return new Vector2(v.x, v.y);</para>
            ///</summary>
            return new Vector2(v.x, v.y);

        }

        public static Vector2 ToVector2YZ(this Vector3 v)
        {
            return new Vector2(v.y, v.z);
        }

        public static Vector2 ToVector2XZ(this Vector3 v)
        {
            return new Vector2(v.x, v.z);
        }
        ///<summary>
        ///return new Vector3(v.x, v.y, 0)
        ///</summary>
        public static Vector3 ToVector3Z(this Vector2 v)
        {


            ///</summary>
            return new Vector3(v.x, v.y, 0);
        }

        public static Vector3 ToVector3Y(this Vector2 v)
        {
            ///<summary>
            ///<para> return new Vector3(v.x, 0, v.y);</para>
            ///</summary>
            return new Vector3(v.x, 0, v.y);
        }

        public static Vector3 ToVector3X(this Vector2 v)
        {
            ///<summary>
            ///<para>return new Vector3(0, v.x, v.y);</para>
            ///</summary>
            return new Vector3(0, v.x, v.y);
        }

        public static Vector3 Round(this Vector3 v)
        {
            return new Vector3(Mathf.Round(v.x), Mathf.Round(v.y), Mathf.Round(v.z));
        }

        public static Vector3 Random(this Vector3 v)
        {
            return new Vector3(UnityEngine.Random.Range(-1, 1), UnityEngine.Random.Range(-1, 1), UnityEngine.Random.Range(-1, 1));
        }

        public static Vector3 Min(this Vector3 v, float min)
        {
            return new Vector3(Mathf.Min(v.x, min), Mathf.Min(v.y, min), Mathf.Min(v.z, min));
        }

        public static Vector3 Min(this Vector3 v, Vector3 min)
        {
            return new Vector3(Mathf.Min(v.x, min.x), Mathf.Min(v.y, min.y), Mathf.Min(v.z, min.z));
        }

        public static Vector3 Max(this Vector3 v, float max)
        {
            return new Vector3(Mathf.Max(v.x, max), Mathf.Max(v.y, max), Mathf.Max(v.z, max));
        }

        public static Vector3 Max(this Vector3 v, Vector3 max)
        {
            return new Vector3(Mathf.Max(v.x, max.x), Mathf.Max(v.y, max.y), Mathf.Max(v.z, max.z));
        }

        public static Vector3 Clamp(this Vector3 v, Vector3 min, Vector3 max)
        {
            return new Vector3(Mathf.Clamp(v.x, min.x, max.x), Mathf.Clamp(v.y, min.y, max.y), Mathf.Clamp(v.z, min.z, max.z));
        }

        public static Vector3 Clamp(this Vector3 v, float min, float max)
        {
            return new Vector3(Mathf.Clamp(v.x, min, max), Mathf.Clamp(v.y, min, max), Mathf.Clamp(v.z, min, max));
        }

        public static Vector3 Lerp(this Vector3 a, Vector3 b, float t)
        {
            return new Vector3(Mathf.Lerp(a.x, b.x, t), Mathf.Lerp(a.y, b.y, t), Mathf.Lerp(a.z, b.z, t));
        }

        public static Vector3 Abs(this Vector3 v)
        {
            return new Vector3(Mathf.Abs(v.x), Mathf.Abs(v.y), Mathf.Abs(v.z));
        }

        public static Vector2 Abs(this Vector2 v)
        {
            return new Vector2(Mathf.Abs(v.x), Mathf.Abs(v.y));
        }

        public static Vector2 Clamp(this Vector2 v, Vector2 min, Vector2 max)
        {
            return new Vector2(Mathf.Clamp(v.x, min.x, max.x), Mathf.Clamp(v.y, min.y, max.y));
        }

        public static Vector2 Clamp(this Vector2 v, float min, float max)
        {
            return new Vector2(Mathf.Clamp(v.x, min, max), Mathf.Clamp(v.y, min, max));
        }

        public static Bounds Mul(this Bounds b, float val)
        {
            return new Bounds(b.center, b.size * val);
        }

        public static Vector3 Mul(this Vector3 A, Vector3 B)
        {
            return new Vector3(A.x * B.x, A.y * B.y, A.z * B.z);
        }

        public static Vector3 toV3(this float f)
        {
            return new Vector3(f, f, f);
        }

        public static Vector2 toV2(this float f)
        {
            return new Vector2(f, f);
        }

        public static Vector3 MaxPosByVector(Vector3 distant, Vector3 source, float maxDistance, Vector3 axis, bool verbose = false)
        {
            Vector3 path = source - distant;


            Vector3 result;

            if (path.magnitude < maxDistance)
            {
                if (verbose)
                    Debug.Log("Inférieure au max: " + maxDistance.ToString());
                //return distant;
                result = distant;
            }
            else
            {
                float RelativeDist = maxDistance / path.magnitude;

                float x = source.x + (RelativeDist * path.x) * -axis.x;
                float y = source.y + (RelativeDist * path.y) * -axis.y;
                float z = source.z + (RelativeDist * path.z) * -axis.z;

                result = new Vector3(x, y, z);

            }




            if (verbose)
            {
                Debug.Log("Distance: " + path.magnitude);
                Debug.DrawLine(source, distant, Color.red);
                Debug.DrawLine(source, result, Color.green);
            }

            return result;
        }

        public static Vector3 PosByVector(Vector3 distant, Vector3 source, float Distance, Vector3 axis, bool verbose = false)
        {
            Vector3 path = source - distant;


            Vector3 result;


            float RelativeDist = Distance / path.magnitude;

            float x = source.x + (RelativeDist * path.x) * -axis.x;
            float y = source.y + (RelativeDist * path.y) * -axis.y;
            float z = source.z + (RelativeDist * path.z) * -axis.z;

            result = new Vector3(x, y, z);






            if (verbose)
            {
                Debug.Log("Distance: " + path.magnitude);
                Debug.DrawLine(source, distant, Color.red);
                Debug.DrawLine(source, result, Color.green);
            }

            return result;
        }

    }

}
