using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class MonoRaymarcher : MonoBehaviour
{
    private Vector3[] spherePos = new Vector3[]
        {new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 2, 0), new Vector3(0, 4, 2)};

    private float[] sphereRadius = new float[] {1, 2, 1, 3};
    
    
    struct CustomRay
    {
        public Vector3 origin;
        public Vector3 dir;
        public Vector3 invdir;
    };
    
    struct Sphere
    {
        public Vector3 center;
        public float radius;
        public float radius2;
    };
    
    struct SphereIntersectionResult
    {
        public bool Intersect;
        public Vector3 point1;
        public Vector3 point2;
        public Vector3 normal1;
    };
    
    CustomRay CreateRay(Vector3 origin, Vector3 dir)
    {
        CustomRay r;
        r.origin = origin;
        r.dir = dir;
        r.invdir = -dir;
        
        return r;
    }
    
    Sphere CreateSphere(Vector3 c, float r)
    {
        Sphere s;
        s.center = c;
        s.radius = r;
        s.radius2 = r*r;
        return  s;
    }
    
    SphereIntersectionResult OldSphereIntersection(Sphere s, CustomRay r)
    {
        SphereIntersectionResult result = new SphereIntersectionResult();
        
        Vector3 L = r.origin - s.center; 
        float a = Vector3.Dot(r.dir, r.dir);
        float b = 2 * Vector3.Dot(r.dir, L);
        float c = Vector3.Dot(L, L) - s.radius2;

        float discr = b * b - 4 * a * c;

        if (discr < 0){
            result.Intersect = false;
        }else if (discr == 0)
        {
            float v = 0.5f*b/a;
            result.point1 = r.origin+r.dir*v;
            result.point2 = r.origin+r.dir*v;

            result.normal1 = Vector3.Normalize(result.point1-s.center);

            result.Intersect = true;
        }
        else
        {
            float q = (b > 0) ? -0.5f * (b+Mathf.Sqrt(discr)) : -0.5f * (b-Mathf.Sqrt(discr));

            float x0 = q/a;
            float x1 = c/q;
            
            result.point1 = r.origin+r.dir * Mathf.Min(x0,x1);
            result.point2 = r.origin+r.dir* Mathf.Max(x0,x1);

            result.normal1 = Vector3.Normalize(result.point1-s.center);

            result.Intersect = true;
        }

        

        return result;
    }

    Vector3 VPow(Vector3 v)
    {
        v.x *= v.x;
        v.y *= v.y;
        v.z *= v.z;
        return v;
    }
    
    SphereIntersectionResult SphereIntersection(Sphere s, CustomRay r)
    {
        SphereIntersectionResult result = new SphereIntersectionResult();
        
// Calculate ray start's offset from the sphere center
        Vector3 p = r.origin - s.center;

        float rSquared = s.radius2;
        float p_d = Vector3.Dot(p, r.dir);

// The sphere is behind or surrounding the start point.
        if (p_d > 0 || Vector3.Dot(p, p) < rSquared)
        {
            result.Intersect = false;
            return result;
        }

// Flatten p into the plane passing through c perpendicular to the ray.
// This gives the closest approach of the ray to the center.
        Vector3 a = p - p_d * r.dir;

        float aSquared = Vector3.Dot(a, a);

// Closest approach is outside the sphere.
        if (aSquared > rSquared)
        {
            result.Intersect = false;
            return result;
        }

// Calculate distance from plane where ray enters/exits the sphere.    
        float h = Mathf.Sqrt(rSquared - aSquared);

// Calculate intersection point relative to sphere center.
        Vector3 i = a - h * r.dir;

        Vector3 intersection = s.center + i;
        Vector3 normal = i/s.radius;

        result.point1 = intersection;
        result.normal1 = normal;
        result.Intersect = true;
// We've taken a shortcut here to avoid a second square root.
// Note numerical errors can make the normal have length slightly different from 1.
// If you need higher precision, you may need to perform a conventional normalization.

        return result;
    }

    
    Vector3 nearestPointOnLine(Vector3 lineA, Vector3 lineDir, Vector3 targetPoint)
    {
        Vector3 v = targetPoint-lineA;
        float d = Vector3.Dot(lineDir,v );
        return lineA+lineDir*d;
    }
    
    Vector3 GetClosestPoint(CustomRay r, Sphere s)
    {
        SphereIntersectionResult result = SphereIntersection(s,r);

        if (result.Intersect)
        {
            return result.point1;
        }else{
             return nearestPointOnLine(r.origin, r.dir, s.center);
            //return new Vector3(9999,9999,9999);
        }
        
    }
    
    PointAndNormal GetClosestPointAndNormal(CustomRay r, Sphere s)
    {
        SphereIntersectionResult result = SphereIntersection(s,r);

        PointAndNormal output = new PointAndNormal();
        output.point = new Vector3(999, 999, 999);
        output.normal = Vector3.zero;

        if (result.Intersect)
        {
            output.point = result.point1;
            DebugQuirk(output.point, Color.cyan);
            output.normal = result.normal1;
        }else{
            output.point = nearestPointOnLine(r.origin, r.dir, s.center);
            DebugQuirk(output.point, Color.blue);
            //return new Vector3(9999,9999,9999);
        }

        return output;
    }

    struct PointAndNormal
    {
        public Vector3 point;
        public Vector3 normal;
    }
    
    Vector3 FindClosestPoint(CustomRay ray)
    {
        float minDist = 999999;
        Vector3 result = new Vector3(999,999,999);
        for (int i = 0; i < spherePos.Length; i++)
        {
            Sphere s = CreateSphere(spherePos[i], sphereRadius[i]);

            Vector3 closestPoint = GetClosestPoint(ray,s);
            float d = Vector3.Distance(closestPoint, ray.origin);

            if (d < minDist)
            {
                minDist= d;
                result = closestPoint;
            }
        }

        return result;
    }
    
    PointAndNormal FindClosestPointAndNormal(CustomRay ray)
    {
        PointAndNormal result = new PointAndNormal();
        
        float minDist = 999999;
       // Vector3 result = new Vector3(999,999,999);
       result.point = new Vector3(999, 999, 999);
       result.normal = Vector3.zero;
       
        for (int i = 0; i < spherePos.Length; i++)
        {
            Sphere s = CreateSphere(spherePos[i], sphereRadius[i]);

            PointAndNormal closestPoint = GetClosestPointAndNormal(ray, s);
            float d = Vector3.Distance(closestPoint.point, ray.origin);

            if (d < minDist)
            {
                minDist= d;
                result.point = closestPoint.point;
                result.normal = closestPoint.normal;
            }
        }

        return result;
    }
    
    // Start is called before the first frame update
    void Start()
    {
        
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.magenta;
        
        for (int i = 0; i < spherePos.Length; i++)
        {
            Gizmos.DrawWireSphere(spherePos[i], sphereRadius[i]);
        }
    }

    public void DebugQuirk(Vector3 pos, Color color)
    {
        Debug.DrawLine(pos, pos + Vector3.forward, color);
        Debug.DrawLine(pos, pos + Vector3.right, color);
        Debug.DrawLine(pos, pos + Vector3.up, color);
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 from = transform.position;
        Vector3 dir = transform.forward;

        CustomRay ray = CreateRay(from, dir);
        Debug.DrawRay(from, dir*1000, Color.green);

        PointAndNormal closestPoint = FindClosestPointAndNormal(ray);
        DebugQuirk(closestPoint.point, Color.yellow);
        Debug.DrawRay(closestPoint.point, closestPoint.normal, Color.red);
        
        
    }
}
