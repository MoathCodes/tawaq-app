#!/bin/bash

echo "Running Performance Optimization Tests..."
echo "======================================="

echo ""
echo "1. Testing PerformanceUtils caching..."
flutter test test/performance/performance_utils_test.dart

echo ""
echo "2. Testing PageNumberWidget optimization..."
flutter test test/widgets/page_number_widget_test.dart

echo ""
echo "3. Testing PageAyahWidget optimization..."
flutter test test/widgets/page_ayah_widget_test.dart

echo ""
echo "4. Testing MushafController optimization..."
flutter test test/logic/mushaf_controller_test.dart

echo ""
echo "5. Running basic integration tests..."
flutter test test/integration/performance_integration_test.dart --plain-name "should render MushafPage efficiently"

echo ""
echo "Performance tests completed!"
echo "============================"
