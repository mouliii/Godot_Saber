#pragma once

#include <Windows.h>
#include <NuiApi.h>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/quaternion.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/classes/image_texture.hpp>


struct SmoothningParams
{
    float fSmoothing = 0.5f;
    float fCorrection = 0.5f;
    float fPrediction = 0.5f;
    float fJitterRadius = 0.05f;
    float fMaxDeviationRadius = 0.04f;
};

using namespace godot;

class KinectWrapper : public Node3D
{
    GDCLASS(KinectWrapper, Node3D);
public:
    KinectWrapper();
    ~KinectWrapper();
    bool InitKinect();
    bool GetSkeletonFrame();
    Array GetJointPositions();
    TypedArray<Vector4> GetPositions();
    Array GetRotations();
    Array GetQuaternions();
    Array GetXforms();
    Ref<ImageTexture> GetDepthFrame();
    bool IsOnline();
    void SetfSmoothing(float val);
    void SetfCorrection(float val);
    void SetfPrediction(float val);
    void SetfJitterRadius(float val);
    void SetfMaxDeviationRadius(float val);
    float GetfSmoothing();
    float GetfCorrection();
    float GetfPrediction();
    float GetfJitterRadius();
    float GetfMaxDeviationRadius();
public:
    SmoothningParams smoothningParams;
private:
    INuiSensor* pKinect = nullptr;
    HANDLE streamHandle;
    HANDLE pSkeletonEventHandle;
    Ref<ImageTexture> imageTexture;
    Array jointPositions;
    Array rotations;
    Array xforms;
    Array quaternions;
    bool online = false;
protected:
    static void _bind_methods();
    
};


// scons platform=windows bits=64