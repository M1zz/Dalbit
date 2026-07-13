//
//  CircularSlider.swift
//  RelaxOn
//
//  Created by 황석현 on 2023/05/25.
//
/**
 원하는 width 크기만큼의 원형 슬라이더를 만드는 View 객체
 SoundDetailView의 원형 슬라이더로
 사운드 커스텀에 사용되는 슬라이더
 */

import SwiftUI

struct DragCircularSlider: View {
    
    @EnvironmentObject var viewModel: CustomSoundViewModel
    
    @State var type: CircleType
    @State private var currentFilterIndex = 0
    
    /// 회전각도 관련 속성
    @State var angle: Double = 0.0
    
    /// 이미지의 위치와 방향을 정하는 속성
    @State private var rotationAngle = Angle(degrees: 0)
    
    var imageName: String
    var angleChanged: (Double) -> Void
    var isOnDrag: Bool = true
    @State var isMoved: Bool = false
    
    private var minValue = 0.0
    private var maxValue = 1.0
    private var width: CGFloat { type.width }
    
    // 슬라이더의 angle값을 반환
    init(type: CircleType, imageName: String, range: [Float], angleChanged: @escaping (Double) -> Void) {
        self.type = type
        self.imageName = imageName
        self.angleChanged = angleChanged
        self.minValue = Double(range.first ?? 0)
        self.maxValue = Double(range.last ?? 1)
    }
    
    var body: some View {
        
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 24)
        // FIXME: rotationAngle이 +90이 되는 현상
            .rotationEffect(-rotationAngle + Angle(degrees: 90))
            .offset(x: width / 2)
            .rotationEffect(rotationAngle - Angle(degrees: 90))
            .gesture(
                DragGesture(minimumDistance: 0.0)
                    .onChanged(){ value in onDrag(value: value.location) }

            )
            .onAppear {
                self.rotationAngle = Angle(degrees: progressFraction * 360.0)
            }
    }
    
    // 슬라이드형 움직임
    func onDrag(value: CGPoint) {
        // 입력 받은 위치로 벡터를 생성합니다. (iOS는 y축이 반대 방향이므로 -y로 설정합니다.)
        let vector = CGVector(dx: value.x, dy: -value.y)
        
        // atan2 함수를 사용하여 벡터의 각도를 계산합니다.
        let angleRadians = atan2(vector.dx, vector.dy)
        
        // 각도가 음수인 경우를 대비해, 각도를 0 ~ 2π 범위로 맞춥니다.
        let positiveAngle = angleRadians < 0.0 ? angleRadians + (2.0 * .pi) : angleRadians
        
        // 계산된 각도를 이용해서 angle 값을 업데이트합니다.
        angle = ((positiveAngle /  (2.0 * .pi)) * (maxValue - minValue )) + minValue
        angleChanged(angle)
        
        rotationAngle = Angle(radians: positiveAngle)
    }
    
    // 진행률을 계산하는 private 변수입니다.
    private var progressFraction: Double {
        // 진행률은 현재 값에서 최소값을 빼고, 그 결과를 (최대값 - 최소값)으로 나눈 값입니다.
        return ((angle - minValue) / (maxValue - minValue))
    }
    
    func calculateAngle(from value: CGPoint) -> (Double, Double) {
        let vector = CGVector(dx: value.x, dy: -value.y)
        let angleRadians = atan2(vector.dx, vector.dy)
        let positiveAngle = angleRadians < 0.0 ? angleRadians + (2.0 * .pi) : angleRadians
        
        // 계산된 각도를 이용해서 angle 값을 업데이트합니다.
        let newAngle = ((positiveAngle /  (2.0 * .pi)) * (maxValue - minValue )) + minValue
        
        return (newAngle, positiveAngle)
    }

}

struct preDragCircularSliderView_Previews: PreviewProvider {
    static var previews: some View {
        DragCircularSlider(type: .medium, imageName: "filter", range: [1.0]) { _ in }
            .environmentObject(CustomSoundViewModel())
    }
}
