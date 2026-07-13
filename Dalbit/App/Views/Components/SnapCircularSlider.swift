//
//  SnapCircularSlider.swift
//  RelaxOn
//
//  Created by 황석현 on 2023/06/15.
//

import SwiftUI

struct SnapCircularSlider: View {
    
    @EnvironmentObject var viewModel: CustomSoundViewModel
    
    @State var type: CircleType
    @State private var currentFilterIndex = 0
    
    /// 이미지의 위치와 방향을 정하는 속성
    @State private var rotationAngle = Angle(degrees: 0)
    
    var imageName: String
    @State var isMoved: Bool = false
    
    private var width: CGFloat { type.width }
    
    // 슬라이더의 angle값을 반환
    init(type: CircleType, imageName: String) {
        self.type = type
        self.imageName = imageName
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
                    .onChanged(){ value in
                        onMove(value: value.location, isMoved: $isMoved)
                        changeFilter()
                    }
                )
    }
    func onMove(value: CGPoint, isMoved: Binding<Bool>) {
        // 입력 받은 위치로 벡터를 생성합니다. (iOS는 y축이 반대 방향이므로 -y로 설정합니다.)
        let vector = CGVector(dx: value.x, dy: -value.y)
        
        // atan2 함수를 사용하여 벡터의 각도를 계산합니다.
        let angleRadians = atan2(vector.dx, vector.dy)
        
        let positiveAngleRange: CGFloat = 2.0 * .pi
        
        // 각도가 음수인 경우를 대비해, 각도를 0 ~ 2π 범위로 맞춥니다.
        let positiveAngle = angleRadians < 0.0 ? angleRadians + (2.0 * .pi) : angleRadians
        
        // snappedAngle을 5칸으로 분류
        let snappedAngle = round((positiveAngle / positiveAngleRange) * 5.0)
        let snappedPositiveAngle = (positiveAngleRange / 5.0) * snappedAngle
        
        currentFilterIndex = Int(snappedAngle) % 5
        let angleDifference = positiveAngle - snappedPositiveAngle
        let adjustedAngle = snappedPositiveAngle + (angleDifference * 0.2)
        
        if snappedAngle == 0 && !isMoved.wrappedValue{
            rotationAngle = -Angle(radians: -adjustedAngle)
            print("rotationAngle = \(rotationAngle)")
            isMoved.wrappedValue = true
        } else {
            if isMoved.wrappedValue {
                        rotationAngle = -Angle(radians: -adjustedAngle)
                        print("rotationAngle = \(rotationAngle)")
            } else {
                rotationAngle = -Angle(radians: -adjustedAngle)
                print("rotationAngle = \(rotationAngle)")
            }
        }
    }
    
    func changeFilter() {
        currentFilterIndex = (currentFilterIndex) % viewModel.filters.count
        DispatchQueue.main.async {
            viewModel.sound.filter = viewModel.filters[currentFilterIndex]
            if viewModel.isPlaying {
                viewModel.stopSound()
            }
            viewModel.play(with: viewModel.sound)
        }
    }
}
