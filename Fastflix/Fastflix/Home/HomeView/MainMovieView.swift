//
//  MainMovieView.swift
//  Fastflix
//
//  Created by Jeon-heaji on 23/07/2019.
//  Copyright © 2019 hyeoktae kwon. All rights reserved.
//

import UIKit
import SnapKit
import Kingfisher
import AVKit

protocol MainMovieViewDelegate: class {
  func didTapPreview(indexPath: IndexPath, logoArr: [URL?]?, videoItems: [AVPlayerItem]?, idArr: [Int]?)
}

final class MainMovieView: UIView {
  
  weak var myDelegate: MainMovieViewDelegate?
  
  var receiveData: RequestMovie? = nil
  var receiveKeys: [String]? = nil
  
  private var originValue: CGFloat = 0
  
  private var compareArr: [CGFloat] = []
  
  var mainMovieId: Int?
  
  private var originY: CGFloat {
    get {
      return floatingView.frame.origin.y
    }
    set {
      guard newValue >= -floatingView.frame.height || newValue <= 0 else { return }
      floatingView.frame.origin.y = newValue
    }
  }
  
  let floatingView: FloatingView = {
    let view = FloatingView()
    view.movieBtn.setTitle("장르", for: .normal)
    return view
  }()
  
  let tableView = UITableView()
  
  weak var delegate: SubTableCellDelegate?
  
  weak var mainDelegate: MainImageTableCellDelegate?
  
  override func didMoveToSuperview() {
    super.didMoveToSuperview()
    addSubViews()
    setupSNP()
    setupTableView()
    registerTableViewCell()
  }
  
  private func setupTableView() {
    tableView.dataSource = self
    tableView.delegate = self
    tableView.backgroundColor = #colorLiteral(red: 0.07762928299, green: 0.07762928299, blue: 0.07762928299, alpha: 1)
    tableView.separatorStyle = .none
    tableView.allowsSelection = false
    
  }
  
  private func registerTableViewCell() {
    tableView.register(MainImageTableCell.self, forCellReuseIdentifier: MainImageTableCell.identifier)
    tableView.register(PreviewTableCell.self, forCellReuseIdentifier: PreviewTableCell.identifier)
    tableView.register(SubCell.self, forCellReuseIdentifier: SubCell.identifier)
    
  }
  
  private func addSubViews() {
    [tableView, floatingView]
      .forEach { self.addSubview($0) }
  }
  
  private func setupSNP() {
    tableView.snp.makeConstraints {
      $0.top.leading.trailing.bottom.equalToSuperview()
    }
    
    floatingView.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(50 + topPadding)
      $0.top.equalToSuperview().offset(-10)
    }
  }
  
  
}

extension MainMovieView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return (receiveKeys?.count ?? 8) + 2
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let mainData = receiveData?[0]
    
    
    switch indexPath.row {
    case 0:
      let cell = tableView.dequeueReusableCell(withIdentifier: MainImageTableCell.identifier, for: indexPath) as! MainImageTableCell
      
      var text = ""
      
      if let data = mainData?.mainMovie.genre {
        for idx in 0...data.count {
          if idx < 3 {
            text += (data[idx].name + "･")
          }
        }
      }
      
      let lastText = String(text.dropLast())
      
      cell.selectionStyle = .none
      
      let id = mainData?.mainMovie.id
      
      cell.delegate = self
      cell.movieId = id
      self.mainMovieId = id
//      cell.mainMovie = mainData?.mainMovie
      cell.configure(imageURLString: mainData?.mainMovie.bigImagePath, logoImageURLString: mainData?.mainMovie.logoImagePath)
      cell.movieDetailLabel.text = lastText
      return cell
      
    case 1:
      let cell = tableView.dequeueReusableCell(withIdentifier: PreviewTableCell.identifier, for: indexPath) as! PreviewTableCell
      let path = DataCenter.shared
      
      var mainURLs: [String] = []
      var logoURLs: [String] = []
      var idArr: [Int] = []
      var videoPathArr: [String] = []
      
      if let data = path.preViewCellData {
        for index in data {
          mainURLs.append(index.circleImage)
          logoURLs.append(index.logoImagePath)
          idArr.append(index.id)
          videoPathArr.append(index.verticalSampleVideoFile ?? "")
        }
      }
//      print("check: ", logoURLs)
      cell.configure(idArr: idArr.reversed(), mainURLs: mainURLs.reversed(), logoURLs: logoURLs.reversed(), videos: videoPathArr.reversed())
      cell.delegate = self
      cell.selectionStyle = .none
      cell.layoutIfNeeded()
      return cell
    default:
    var mainImgUrl: [String] = []
    var movieIDArr: [Int] = []
    let keys = mainData!.listOfGenre
    let key = keys[indexPath.row - 2]
    print("key: ", key)
    
    if let data = mainData {
      for idx in data.moviesByGenre[key]! {
        mainImgUrl.append(idx.verticalImage)
        movieIDArr.append(idx.id)
      }
    }
    print("count: ", mainImgUrl)
    let cell = SubCell()
    cell.configure(url: mainImgUrl, title: key, movieIDs: movieIDArr)
    cell.delegate = self
    return cell
    }
  }
  
  
}

extension MainMovieView: UITableViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
    //    print(scrollView.contentOffset.y)
    let offset = scrollView.contentOffset.y
    
    let transition = scrollView.panGestureRecognizer.translation(in: scrollView).y.rounded()
    
    let fixValue = floatingView.frame.size.height
    
    var floatValue: CGFloat {
      get {
        return originValue
      }
      set {
        if newValue > -fixValue && newValue < 0 {
          originValue = newValue
        } else if newValue < -fixValue {
          originValue = -fixValue
        } else {
          return
        }
        
      }
    }
    
    
    
    if compareArr.count > 1 {
      compareArr.remove(at: 0)
    }
    compareArr.append(offset)
    
    if offset <= -topPadding {
      floatingView.frame.origin.y = -10
      return
    }
    
    if compareArr.count == 2 {
      if compareArr[0] > compareArr[1] {
        // show
        let addtionalValue = compareArr[1] - compareArr[0]
        floatValue += -addtionalValue
        originY = floatValue - 10
        return
      } else if compareArr[0] < compareArr[1] {
        // hide
        let addtionalValue = compareArr[1] - compareArr[0]
        floatValue += -addtionalValue
        originY = floatValue - 10
        return
      } else {
        return
      }
    }
    
    
  }
}


extension MainMovieView: PreviewTableCellDelegate {
  func didSelectItemAt(indexPath: IndexPath, logoArr: [URL?]?, videoItems: [AVPlayerItem]?, idArr: [Int]?) {
    myDelegate?.didTapPreview(indexPath: indexPath, logoArr: logoArr, videoItems: videoItems, idArr: idArr)
  }
}

extension MainMovieView: SubTableCellDelegate {
  func didSelectItemAt(movieId: Int, movieInfo: MovieDetail) {
    delegate?.didSelectItemAt(movieId: movieId, movieInfo: movieInfo)
  }
  
  func errOccurSendingAlert(message: String, okMessage: String) {
    delegate?.errOccurSendingAlert(message: message, okMessage: okMessage)
  }
}


extension MainMovieView: MainImageTableCellDelegate {
  func playVideo(id: Int) {
    mainDelegate?.playVideo(id: mainMovieId!)
  }
  
  func mainImageCelltoDetailVC(id: Int) {
    mainDelegate?.mainImageCelltoDetailVC(id: mainMovieId!)
  }
  
}
