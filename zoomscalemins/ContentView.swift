//
//  ContentView.swift
//  zoomscalemins
//
//  Created by Michael Langford on 3/19/21.
//

import SwiftUI

extension Color{
  static var aqua:Color{
    return Color(red:0.32, green:0.88, blue:0.85)
  }
}

struct CornerRadius: View{
  var body: some View{
    GeometryReader { geometry in
      let screenWidth = geometry.size.width-2
      let screenHeight = geometry.size.height-2
      Path { path in
        path.move(to: CGPoint(x:screenWidth, y:1))
        path.addLine(to: CGPoint(x: screenWidth/2, y: screenHeight/2))
      }.stroke(Color.red, lineWidth: 2)
    }
  }
}

extension CGSize {
  var shortestRadiusLength:CGFloat {
    if width < height {
      return width/2.0
    } else {
      return height/2.0
    }
  }

  var shortestRadiusAngle:CGFloat{
      if width < height {
        return .pi / 2.0
      } else {
        return 0
      }
  }

  var mediumRadiusLength:CGFloat{
    if height < width {
      return width/2.0
    } else {
      return height/2.0
    }
  }
  var mediumRadiusAngle:CGFloat{
    if height < width {
      return  .pi/2.0
    } else {
      return 0
    }
  }

  var longestRadiusLength:CGFloat{
    sqrt((mediumRadiusLength*mediumRadiusLength) + (shortestRadiusLength*shortestRadiusLength))
  }

  var longestRadiusAngle:CGFloat{
    atan2(width,height)
  }

  var aspectRatio:CGFloat{
    width/height
  }
}

struct SmallRadius: View{
  var body: some View{
    
    GeometryReader { geometry in
      let size = geometry.size
      let center = CGPoint(
        x: size.width/2,
        y: size.height/2
      )
      let angle = size.shortestRadiusAngle
      let endpoint = CGPoint(
        x: center.x + (center.x * sin(angle)),
        y: center.y - (center.y * cos(angle))
      )
      Path { path in
        path.move(to:center)
        path.addLine(to: endpoint)
      }.stroke(Color.aqua, lineWidth: 2)
    }
  }
}



struct MediumRadius: View{
  var body: some View{

    GeometryReader { geometry in
      let size = geometry.size
      let center = CGPoint(
        x: size.width/2,
        y: size.height/2
      )
      let angle = size.mediumRadiusAngle
      let endpoint = CGPoint(
        x: center.x + (center.x * sin(angle)),
        y: center.y - (center.y * cos(angle))
      )
      Path { path in
        path.move(to:center)
        path.addLine(to: endpoint)
      }.stroke(Color.yellow, lineWidth: 2)
    }
  }
}

struct ContentView: View {
  @State private var additionalRotation:CGFloat = 0
  @State private var zoom:CGFloat = 0

  var body: some View {
     
      VStack{
        HStack{

          Text(
            "Manual Zoom Adj: \(Int(100*additionalZoomPercentage(additionalZoom: zoom)))%"
          )
        }
        HStack{

          Button ("Zoom +"){
            zoom += 1.0
          }
          Button("   ->   ") {
            additionalRotation += 1.0
          }

          Button("   <-   ") {
            additionalRotation -= 1.0
          }

          Button ("Zoom -"){
            zoom -= 1.0
          }
        }

        ZStack(alignment: .center)  {
          GeometryReader { geometry in
          let screenWidth = geometry.size.width-2
          let screenHeight = geometry.size.height-2
            let startingAngle = rad2deg(geometry.size.longestRadiusAngle)


          Rectangle()
            .path(in: CGRect(x: 1,
                         y: 1,
                         width: screenWidth ,
                         height: screenHeight ))
            .foregroundColor(.black)

          SmallRadius()
          MediumRadius()
          CornerRadius()



          InnerView(rotation: startingAngle + additionalRotation , additionalZoom: zoom)
            Text ("Image Rot: \(Int(additionalRotation+startingAngle))°").frame(width: geometry.size.width, height: 24, alignment: .top).foregroundColor(.white)

        }

      }
    }
  }
}

func deg2Rad(_ number: CGFloat) -> CGFloat {
  return (number * .pi) / 180.0
}

func rad2deg(_ number: CGFloat) -> CGFloat {
  return number * 180 / .pi
}
func additionalZoomPercentage(additionalZoom:CGFloat)->CGFloat{
  (additionalZoom * 0.05) + 1.0
}

var variableRangeString = ""

struct InnerView: View {


  func minimumAllowedZoom(_ angle:CGFloat, viewSize:CGSize, imageSize:CGSize) -> CGFloat {

    let isViewWiderAspectRatio = viewSize.aspectRatio < imageSize.aspectRatio
    let scaleMin =  isViewWiderAspectRatio ? viewSize.shortestRadiusLength/imageSize.shortestRadiusLength
      : viewSize.mediumRadiusLength/imageSize.mediumRadiusLength
    let _ = dump(("Short image aligned with short view", scaleMin))

    let scaleMax = viewSize.longestRadiusLength/imageSize.shortestRadiusLength
    let _ = dump(("Zoom Req when short image across view corners", scaleMax))

    let variableRange = scaleMax - scaleMin
    variableRangeString = "Zoom levels vary between \(scaleMax) and \(scaleMin) (variation \(variableRange))"
    print(variableRangeString)

    var clampedZoom = scaleMax
    /// todo, write clamping problem here




    return clampedZoom
  }


    var image:UIImage = UIImage(named: "CircleImage")!
    var rotation:CGFloat
    var additionalZoom:CGFloat


    var body: some View {
      GeometryReader { geo in

        let viewSize = geo.size
        let _ = dump(geo.size)

        let minZoom = minimumAllowedZoom(deg2Rad(rotation),viewSize:viewSize,imageSize:image.size)
        let addZoomPctBased = additionalZoomPercentage(additionalZoom: additionalZoom)
        let actualZoom = max(minZoom,minZoom*addZoomPctBased)

        //let scaleMax = 1
        Image(uiImage:image).scaleEffect(CGSize(width:actualZoom,height:actualZoom), anchor:.center).opacity(0.3).rotationEffect(.degrees(Double(rotation)))
            .position(x: viewSize.width / 2, y: viewSize.height / 2)

        Text("\nimageSize: \(Int(image.size.width))x\(Int(image.size.height))\ngeo:\(Int(geo.size.width))x\(Int(geo.size.height))\nzoomshown:\(actualZoom)\n range:\(variableRangeString)").foregroundColor(Color.orange)
      }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        ContentView()
      }
    }
}
