#include "RectTester.hpp"

using namespace std;
using namespace cv;

vector<vector<Point>> RectTester::RecognizeAnswers(cv::Mat matToRecognize, cv::Rect2d markerRect){
//    double aspect = (double)matToRecognize.rows/(double)matToRecognize.cols;
    
//    Mat resizedImage = Mat(matToRecognize);
//    cv::resize(matToRecognize, resizedImage, Size(800, 800*aspect));
    
    Mat blurImage = Mat(matToRecognize);
    GaussianBlur(matToRecognize, blurImage, Size(5,5), 0);
    //    medianBlur(matToRecognize, blurImage, 9);
    
    Mat grayImage;
    cvtColor(blurImage, grayImage, CV_BGR2GRAY);
    
    Mat mask;
    adaptiveThreshold(grayImage, mask,255,CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY,75,10);
//    threshold(grayImage, mask, 0, 255, CV_THRESH_BINARY_INV | CV_THRESH_OTSU);
    
//    dilate(mask, mask, Mat(), Point(-1,-1));
    
    vector<vector<Point>> contours;
    findContours(mask, contours, RETR_LIST, CHAIN_APPROX_SIMPLE);
    vector<vector<Point>> rectContours;
    for(auto cnt: contours){
        
        vector<Point> approx = vector<Point>();
        double peri = arcLength(cnt, true);
        if(peri < 350 || peri > 800) continue;
        approxPolyDP(cnt, approx, 0.04 * peri, true);
        if(approx.size() != 4 ) continue;
        if(abs(Rect2d(approx[0], approx[2]).width - markerRect.width) > markerRect.width*0.25 ) continue;
        drawContours( matToRecognize, vector<vector<Point>>({cnt}), 0, cv::Scalar(255, 0, 0), 3, 8, noArray(), 0, cv::Point() );
        rectContours.push_back(approx);
        
        
    }
    return rectContours;
}

vector<vector<cv::Point2f>> RectTester::RecognizeMarkers(cv::Mat matToRecognize){
    
    Mat grayImage;
    cvtColor(matToRecognize, grayImage, CV_BGR2GRAY);
    
    std::vector<int> markerIds;
    vector<vector<cv::Point2f>> markerCorners, rejectedCandidates;
    cv::Ptr<cv::aruco::DetectorParameters> parameters = aruco::DetectorParameters().create();
    cv::Ptr<cv::aruco::Dictionary> dictionary = aruco::getPredefinedDictionary(cv::aruco::DICT_ARUCO_ORIGINAL);
    cv::aruco::detectMarkers(grayImage, dictionary, markerCorners, markerIds, parameters, rejectedCandidates);
    
    
    if(markerIds.size() > 0){
//        aruco::drawDetectedMarkers(grayImage, markerCorners,markerIds);
        vector<vector<cv::Point>> markers = vector<vector<cv::Point>>();
        for(auto marker2f: markerCorners){
            vector<cv::Point> marker = vector<cv::Point>();
            for(auto point2f: marker2f){
                marker.push_back(point2f);
            }
            markers.push_back(marker);
        }
        
        for(int i = 0; i < markers.size(); i++){
            drawContours( matToRecognize, markers, i, cv::Scalar(255, 255, 0), 5, 8, noArray(), 0, cv::Point() );
        }
    }
    
    return markerCorners;
}
