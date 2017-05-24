#ifndef RectTester_hpp
#define RectTester_hpp

#include <iostream>
#include <vector>
#include "opencv2/highgui.hpp"
#include "opencv2/imgproc.hpp"
#include "opencv2/core.hpp"
#include "opencv2/aruco.hpp"

using namespace std;
using namespace cv;
    
    class RectTester {
    public:
        static vector<vector<cv::Point>> RecognizeAnswers(cv::Mat matToRecognize);
        static vector<vector<cv::Point2f>> RecognizeMarkers(cv::Mat matToRecognize);
        
    private:
        string imagePath;
    };

#endif /* RectTester_hpp */
