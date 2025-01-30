#include "kinect_wrapper.hpp"


KinectWrapper::KinectWrapper()
{
    UtilityFunctions::print("constructor");
    //InitKinect();
    imageTexture = Ref<ImageTexture>(memnew(ImageTexture));
    Ref<Image> img = Image::create_empty(640,480,false,Image::FORMAT_R8);
    img->fill(Color(0.0f,0.0f,0.0f));
    imageTexture = imageTexture->create_from_image(img);
}

KinectWrapper::~KinectWrapper()
{
    UtilityFunctions::print("destructor");
    if (pKinect)
    {
        pKinect->NuiShutdown();
        pKinect->Release();
    }
}

bool KinectWrapper::InitKinect()
{
    HRESULT hr;
    // create
    hr = NuiCreateSensorByIndex(0, &pKinect); // hard coded single sensor 
    if (FAILED(hr))
    {
        UtilityFunctions::print("could not create kinect sensor!");
        return false;
    }

    // init //
    // NUI_INITIALIZE_FLAG_USES_SKELETON | NUI_INITIALIZE_FLAG_USES_COLOR | NUI_INITIALIZE_FLAG_USES_SKELETON | NUI_INITIALIZE_FLAG_USES_DEPTH_AND_PLAYER_INDEX
    hr = pKinect->NuiInitialize(NUI_INITIALIZE_FLAG_USES_SKELETON | NUI_INITIALIZE_FLAG_USES_DEPTH);
    if (FAILED(hr))
    {
        UtilityFunctions::print("Failed to init kinect");
        pKinect->Release();
        return false;
    }

    // depth camera // https://learn.microsoft.com/en-us/previous-versions/windows/kinect-1.8/hh855368(v=ieb.10)#nui_image-flags
    hr = pKinect->NuiImageStreamOpen(NUI_IMAGE_TYPE_DEPTH, NUI_IMAGE_RESOLUTION_640x480,NUI_IMAGE_STREAM_FLAG_SUPPRESS_NO_FRAME_DATA,2,nullptr,&streamHandle);
    if (hr != S_OK)
    {
        UtilityFunctions::print("could not enable depth stream");
        std::cout << hr << std::endl;
        pKinect->NuiShutdown();
        pKinect->Release();
        return false;
    }

    // Skeleton tracking
    hr = pKinect->NuiSkeletonTrackingEnable(NULL, NUI_SKELETON_TRACKING_FLAG_SUPPRESS_NO_FRAME_DATA); // pSkeletonEventHandle
    if (hr != S_OK)
    {
        UtilityFunctions::print("could not enable skeleton tracking");
        std::cout << hr << std::endl;
        pKinect->NuiShutdown();
        pKinect->Release();
        return false;
    }
    online = true;
    return true;
}

bool KinectWrapper::GetSkeletonFrame()
{
    NUI_SKELETON_FRAME skeletonFrame = { 0 };
    HRESULT hr;
    hr = pKinect->NuiSkeletonGetNextFrame(0, &skeletonFrame);
    if (hr != S_OK)
    {
        return false;
    }
    NUI_TRANSFORM_SMOOTH_PARAMETERS params = { smoothningParams.fSmoothing, smoothningParams.fCorrection, smoothningParams.fPrediction, smoothningParams.fJitterRadius, smoothningParams.fMaxDeviationRadius };
    pKinect->NuiTransformSmooth(&skeletonFrame, &params);

    jointPositions.clear();
    rotations.clear();
    xforms.clear();
    quaternions.clear();
    // Process skeleton data
    for (int i = 0; i < NUI_SKELETON_COUNT; i++)
    {
        NUI_SKELETON_BONE_ORIENTATION boneOrientations[NUI_SKELETON_POSITION_COUNT];
        NuiSkeletonCalculateBoneOrientations(&skeletonFrame.SkeletonData[i], boneOrientations);

        if (skeletonFrame.SkeletonData[i].eTrackingState == NUI_SKELETON_TRACKED)
        {
            
            for (size_t j = 0; j < NUI_SKELETON_POSITION_COUNT; j++)
            {
                // POSITION
                Vector4 position;
                memcpy(&position, &skeletonFrame.SkeletonData[i].SkeletonPositions[j], 4 * sizeof(float));
                jointPositions.append(position);
                // ROTATION
                NUI_SKELETON_BONE_ORIENTATION& orientation = boneOrientations[j];
                Vector4 rot[4];
                memcpy(&rot, &orientation.absoluteRotation.rotationMatrix, 16 * sizeof(float));
                Transform3D xform(Vector3(rot[0].x, rot[0].y, rot[0].z),
                                    Vector3(rot[1].x, rot[1].y, rot[1].z),
                                    Vector3(rot[2].x, rot[2].y, rot[2].z),
                                    Vector3(position.x, position.y, position.z));
                xforms.append(xform);
                
                Quaternion quad = Quaternion();
                memcpy(&quad, &orientation.hierarchicalRotation.rotationQuaternion, 16 * sizeof(float));
                quaternions.append(quad);
            }
        }
    }
    return true;
}

Array KinectWrapper::GetJointPositions()
{
    return jointPositions;
}

Array KinectWrapper::GetRotations()
{
    return rotations;
}

Array KinectWrapper::GetQuaternions()
{
    return quaternions;
}

Array KinectWrapper::GetXforms()
{
    return xforms;
}

Ref<ImageTexture> KinectWrapper::GetDepthFrame()
{
    // https://learn.microsoft.com/en-us/previous-versions/windows/kinect-1.8/hh855610(v=ieb.10)#remarks
    NUI_IMAGE_FRAME imgFrame;
    // https://learn.microsoft.com/en-us/previous-versions/windows/kinect-1.8/jj663862(v=ieb.10)
    HRESULT hr = pKinect->NuiImageStreamGetNextFrame(streamHandle, 0, &imgFrame);
    if(hr != S_OK)
    {   // no update
    /*
        if(hr == S_FALSE){
            UtilityFunctions::print("S_FALSE");
        }else if(hr == E_INVALIDARG){
            UtilityFunctions::print("The value of the hStream parameter is NULL");
        }
        else if(hr == E_POINTER){
            UtilityFunctions::print("The value of the pImageFrame parameter is NULL");
        }
    */
        return imageTexture;
    }
    // https://learn.microsoft.com/en-us/previous-versions/windows/kinect-1.8/hh855614(v=ieb.10)
    NUI_LOCKED_RECT rect;
    PackedByteArray pba;
    imgFrame.pFrameTexture->LockRect(0, &rect, nullptr, 0);
    pba.resize(rect.size / 2);
    // conversion millimetri -> 0.0-1.0 dist:0-4m
    const int minVal = 0;
    const int maxVal = 4*100*10;
    const int maxSubMin = maxVal - minVal;
    int pixelCount = 0;
    for(int i = 0; i < rect.size; i+=2)
    {
        int curVal = (rect.pBits[i+1] << 8) | rect.pBits[i];
        float normVal = (curVal - minVal) / static_cast<float>(maxSubMin);
        int scaledVal = static_cast<int>(normVal * 255);
        pba[pixelCount] = scaledVal;
        pixelCount++;
    }
    Ref<Image> image = Image::create_from_data(640,480,false,Image::FORMAT_R8, pba);
    imageTexture->update(image);
    // RELEASE BUFFER AND FRAME STREAM!!!
    imgFrame.pFrameTexture->UnlockRect(0);
    pKinect->NuiImageStreamReleaseFrame(streamHandle, &imgFrame);

    return imageTexture;
}

bool KinectWrapper::IsOnline()
{
    return online;
}

void KinectWrapper::SetfSmoothing(float val)
{
    smoothningParams.fSmoothing = CLAMP(val, 0.0f, 1.0f);
}

void KinectWrapper::SetfCorrection(float val)
{
    smoothningParams.fCorrection = CLAMP(val, 0.0f, 1.0f);
}

void KinectWrapper::SetfPrediction(float val)
{
    smoothningParams.fPrediction = CLAMP(val, 0.0f, 1.0f);
}

void KinectWrapper::SetfJitterRadius(float val)
{
    smoothningParams.fJitterRadius = CLAMP(val, 0.0f, 1.0f);
}

void KinectWrapper::SetfMaxDeviationRadius(float val)
{
    smoothningParams.fMaxDeviationRadius = CLAMP(val, 0.0f, 1.0f);
}

float KinectWrapper::GetfSmoothing()
{
    return smoothningParams.fSmoothing;
}

float KinectWrapper::GetfCorrection()
{
    return smoothningParams.fCorrection;
}

float KinectWrapper::GetfPrediction()
{
    return smoothningParams.fPrediction;
}

float KinectWrapper::GetfJitterRadius()
{
    return smoothningParams.fJitterRadius;
}

float KinectWrapper::GetfMaxDeviationRadius()
{
    return smoothningParams.fMaxDeviationRadius;
}


void KinectWrapper::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("GetJointPositions"), &KinectWrapper::GetJointPositions);
    ClassDB::bind_method(D_METHOD("GetRotations"), &KinectWrapper::GetRotations);
    ClassDB::bind_method(D_METHOD("GetXforms"), &KinectWrapper::GetXforms);
    ClassDB::bind_method(D_METHOD("GetQuaternions"), &KinectWrapper::GetQuaternions);
    ClassDB::bind_method(D_METHOD("GetSkeletonFrame"), &KinectWrapper::GetSkeletonFrame);
    ClassDB::bind_method(D_METHOD("InitKinect"), &KinectWrapper::InitKinect);
    ClassDB::bind_method(D_METHOD("GetDepthFrame"), &KinectWrapper::GetDepthFrame);
    ClassDB::bind_method(D_METHOD("IsOnline"), &KinectWrapper::IsOnline);

    ADD_GROUP("KinectSmoothningFilter", "*");

    ClassDB::bind_method(D_METHOD("GetfSmoothing"), &KinectWrapper::GetfSmoothing);
    ClassDB::bind_method(D_METHOD("SetfSmoothing", "value1"), &KinectWrapper::SetfSmoothing);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "SmoothValue"), "SetfSmoothing", "GetfSmoothing"); // , PROPERTY_HINT_NONE, "", PROPERTY_USAGE_GROUP), 

    ClassDB::bind_method(D_METHOD("GetfCorrection"), &KinectWrapper::GetfCorrection);
    ClassDB::bind_method(D_METHOD("SetfCorrection", "value2"), &KinectWrapper::SetfCorrection);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "CorrectionValue"), "SetfCorrection", "GetfCorrection");

    ClassDB::bind_method(D_METHOD("GetfPrediction"), &KinectWrapper::GetfPrediction);
    ClassDB::bind_method(D_METHOD("SetfPrediction", "value3"), &KinectWrapper::SetfPrediction);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "PredictionValue"), "SetfPrediction", "GetfPrediction");

    ClassDB::bind_method(D_METHOD("GetfJitterRadius"), &KinectWrapper::GetfJitterRadius);
    ClassDB::bind_method(D_METHOD("SetfJitterRadius", "value4"), &KinectWrapper::SetfJitterRadius);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "JitterRadius"), "SetfJitterRadius", "GetfJitterRadius");

    ClassDB::bind_method(D_METHOD("GetfMaxDeviationRadius"), &KinectWrapper::GetfMaxDeviationRadius);
    ClassDB::bind_method(D_METHOD("SetfMaxDeviationRadius", "value5"), &KinectWrapper::SetfMaxDeviationRadius);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "MaxDeviationRadius"), "SetfMaxDeviationRadius", "GetfMaxDeviationRadius");
    
}