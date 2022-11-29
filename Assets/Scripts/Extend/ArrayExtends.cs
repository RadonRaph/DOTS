using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using Random = UnityEngine.Random;

namespace Raccoonlabs
{

    public static class ArrayExtends
    {
        public static T[] ToLinear<T>(this T[,] arr)
        {
            T[] result = new T[arr.GetLength(0) * arr.GetLength(1)];
            int w = arr.GetLength(0);
            int h = arr.GetLength(1);
            for (int x = 0; x < w; x++)
            {
                for (int y = 0; y < h; y++)
                {
                    result[x + y * w] = arr[x, y];
                }
            }

            return result;
        }

        public static T[] ToLinear<T>(this T[,,] arr)
        {
            T[] result = new T[arr.GetLength(0) * arr.GetLength(1)];
            int w = arr.GetLength(0);
            int h = arr.GetLength(1);
            int l = arr.GetLength(2);
            for (int x = 0; x < w; x++)
            {
                for (int y = 0; y < h; y++)
                {
                    for (int z = 0; z < l; z++)
                    {
                        result[x + y * w + h * l * z] = arr[x, y, z];
                    }
                }
            }
            return result;
        }
        
        public static int ToLinearIndex(Vector2Int index, int width)
        {
            return index.x + index.y * width;
        }
        
        public static int ToLinearIndex(int x, int y, int width)
        {
            return x + y * width;
        }
        
        public static int ToLinearIndex(Vector3Int index, int width, int height, int length)
        {
            return index.x + index.y * width + height * length * index.z;
        }
        
        public static int ToLinearIndex(Vector3 indexF, int width, int height, int length)
        {
            Vector3Int index = new Vector3Int(Mathf.RoundToInt(indexF.x), Mathf.RoundToInt(indexF.y),
                Mathf.RoundToInt(indexF.z));
            
            return index.x + index.y * width + height * length * index.z;
        }

        public static T[,] To2D<T>(this T[] arr, int width, int height)
        {
            T[,] result = new T[width, height];
            for (int i = 0; i < width * height; i++)
            {
                int x = i % width;
                int y = i / height;
                result[x, y] = arr[i];
            }
            return result;
        }

        public static Vector2Int To2DIndex(int index, int width)
        {
            return new Vector2Int(index % width, index/width);
        }

        public static T[,,] To3D<T>(this T[] arr, int width, int height, int length)
        {

            T[,,] result = new T[width, height, length];
            for (int i = 0; i < arr.Length; i++)
            {
                int x = i % width;
                int y = (i / width) % height;
                int z = i / (width * height);
                result[x, y, z] = arr[i];
            }
            return result;
        }
        
        public static Vector3Int To3DIndex(int index, int width, int height)
        {
            return new Vector3Int(index % width, (index / height)%height, index/(width*height));
        }

        public static T[] Shuffle<T>(this T[] array)
        {
            T[] result = array;
            for (int i = 0; i < array.Length; i++)
            {
                int rnd = Random.Range(0, result.Length);
                T tempGO = result[rnd];
                result[rnd] = result[i];
                result[i] = tempGO;
            }
            return result;
        }

        public static int GetIndex<T>(this T[] arr, T match)
        {
            for (int i = 0; i < arr.Length; i++)
            {
                if (match.Equals(arr[i]))
                    return i;
            }
            return -1;
        }
    }

}
