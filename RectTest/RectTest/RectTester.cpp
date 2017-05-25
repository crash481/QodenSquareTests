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
    vector<vector<Point>> filteredContours;
    
    for(auto cnt: contours){
        
        // approximate countour
        vector<Point> approx = vector<Point>();
        double peri = arcLength(cnt, true);
        if(peri < 320 || peri > 800) continue;
        approxPolyDP(cnt, approx, 0.07 * peri, true);
        
        // skip if aproximated is not rect
        if(approx.size() != 4 ) continue;
        
        //skip if rect's height(width because of camera pisition) more/less than marker
        cv::Rect2d contourRect = Rect2d(approx[0], approx[2]);
        if(abs(contourRect.width - markerRect.width) > markerRect.width*0.15 ) continue;
        
        //skip/remove contours that inside another contours
        bool containsAnotherContour = false;
        int addedRectIdx = 0;
        for(auto addedRectContour: rectContours){
            cv::Rect2d addedRect = Rect2d(addedRectContour[0], addedRectContour[2]);
            bool finish = false;
            
            for(auto points: approx){
                if(addedRect.contains(points)){
                    containsAnotherContour = true;
                    finish = true;
                    break;
                }
            }
            
            cv::Rect2d rect = Rect2d(approx[0], approx[2]);
            bool finish2 = false;
            for(auto addedPoints: addedRectContour){
                if(rect.contains(addedPoints)){
                    rectContours.erase(rectContours.begin() + addedRectIdx);
                    filteredContours.erase(filteredContours.begin() + addedRectIdx);
                    finish = true;
                    break;
                }
            }
            if(finish) break;
            addedRectIdx++;
        }
        if(containsAnotherContour) continue;
        

        //RECOGNIZE SCRATCH BY COUNTOURS INSIDE
//        Mat grayContour = matToRecognize(contourRect);
//        cvtColor(grayContour, grayContour, CV_BGR2GRAY);
//        Mat contourMask;
//        threshold(grayContour, contourMask, 0, 255, CV_THRESH_BINARY_INV | CV_THRESH_OTSU);
//        vector<vector<Point>> contoursInCountour;
//        findContours(contourMask, contoursInCountour, RETR_LIST, CHAIN_APPROX_TC89_KCOS);
//        
//        double scratchAreaSum = 0;
//        for(auto cntInCnt: contoursInCountour){
//            double scratchArea = contourArea(cntInCnt);
//            if(scratchArea < 700 ) continue;
//            scratchAreaSum += scratchArea;
//        }
//        
//        double area = contourArea(cnt);
//        int scratchPerc = 100 / area * scratchAreaSum;
//        
//        putText(matToRecognize, to_string(int(scratchPerc)), Point(approx[3].x, (approx[1].y + approx[3].y)/2), FONT_HERSHEY_SIMPLEX, 1.4 , Scalar(155, 100, 205), 3);
        
        rectContours.push_back(approx);
        filteredContours.push_back(cnt);
    }
    
    // drow contours
    for(auto cnt: filteredContours){
        drawContours( matToRecognize, vector<vector<Point>>({cnt}), 0, cv::Scalar(255, 0, 0), 3, 8, noArray(), 0, cv::Point() );
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
