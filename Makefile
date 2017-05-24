all: openCV.framework

openCV.framework:
	curl -L -o "RectTest/RectTest/opencv2.framework.zip" "https://www.dropbox.com/s/dz4firgp2iz7hr8/opencv2.framework.zip?dl=1"
	unzip "RectTest/RectTest/opencv2.framework" -d "RectTest/RectTest"
	rm "RectTest/RectTest/opencv2.framework.zip"

.PHONY: all