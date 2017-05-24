#include "RectTester.hpp"

using namespace std;
using namespace cv;

RectTester::RectTester(const std::string path){
    imagePath = path;
}

vector<vector<Point>> RectTester::recognize() {
    Mat image = imread(imagePath);
    double aspect = (double)image.rows/(double)image.cols;
    
    Mat resizedImage = Mat(image);
    cv::resize(image, resizedImage, Size(300, 300*aspect));
    
    Mat blurImage = Mat(resizedImage);
    GaussianBlur(resizedImage, blurImage, Size(5,5), 0);
    
    Mat grayImage;
    cvtColor(blurImage, grayImage, CV_BGR2GRAY);
    
    Mat mask;
    threshold(grayImage, mask, 0, 255, CV_THRESH_BINARY_INV | CV_THRESH_OTSU);
    
    vector<vector<Point>> contours;
    findContours(mask, contours, RETR_LIST, CHAIN_APPROX_SIMPLE);
    return contours;
}

Mat RectTester::getMat() {
    Mat image = imread(imagePath);
    return getRecognizedMat(image);
}

cv::Mat RectTester::getRecognizedMat(cv::Mat matToRecognize){
//    double aspect = (double)matToRecognize.rows/(double)matToRecognize.cols;
    
//    Mat resizedImage = Mat(matToRecognize);
//    cv::resize(matToRecognize, resizedImage, Size(800, 800*aspect));
    
//    Mat blurImage = Mat(matToRecognize);
//    GaussianBlur(matToRecognize, blurImage, Size(5,5), 0);
    
    Mat grayImage;
    cvtColor(matToRecognize, grayImage, CV_BGR2GRAY);
    
    Mat mask;
    threshold(grayImage, mask, 0, 255, CV_THRESH_BINARY_INV | CV_THRESH_OTSU);
    
    vector<vector<Point>> contours;
    findContours(mask, contours, RETR_LIST, CHAIN_APPROX_SIMPLE);
    
    for(auto cnt: contours){
        
        vector<Point> approx = vector<Point>();
        double peri = arcLength(cnt, true);
        if(peri < 300 || peri > 800) continue;
        approxPolyDP(cnt, approx, 0.035 * peri, true);
        if(approx.size() == 4)
            drawContours( matToRecognize, vector<vector<Point>>({approx}), 0, cv::Scalar(255, 0, 0), 3, 8, noArray(), 0, cv::Point() );
    }
    return matToRecognize;
}

vector<vector<cv::Point2f>> RectTester::getRecognizedMarkers(cv::Mat matToRecognize){
    
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
