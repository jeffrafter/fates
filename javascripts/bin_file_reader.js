/**
 * Based on:
 *
 * BinFileReader.js
 * You can find more about this function at
 * http://nagoon97.com/reading-binary-files-using-ajax/
 *
 * Copyright (c) 2008 Andy G.P. Na <nagoon97@naver.com>
 * The source code is freely distributable under the terms of an MIT-style license.
 */
function BinFileReader(fileURL){
  var _exception = {};
  _exception.FileLoadFailed = 1;
  _exception.EOFReached = 2;
  
  var _filePointer = 0;
  var _fileSize = -1;
  var _fileContents;

  this.size = function() {
    return _fileSize; 
  }
  
  this.pos = function() {
    return _filePointer;
  }
  
  this.seek = function(to){
    if(to < 0) _filePointer = 0;
    else if(to > _fileSize) throwException(_exception.EOFReached);
    else _filePointer = to;    
    return _filePointer;
  };
  
  this.readByte = function(start) {
    start = start || _filePointer;    
    var byte = this.readByteAt(start);
    this.seek(start + 1);    
    return byte;
  }
  
  this.read = function(size, start) {
    size = size || 1;
    if (start) this.seek(start);    
    var index = 0;
    var block = [];    
    for (var i=0; i<size; i++) {
      block[index++] = this.readByte();
    }    
    return block;
  }

  this.blockToNumber = function(block) {
    var result = 0;
    for (var i=block.length; i>0; i--) {
      result = result * 256 + block[i-1];
    }  
    return result;
  }
  
  this.blockToString = function(block) {
    var result = "";
    for (var i=0; i< block.length; i++) {
      result += String.fromCharCode(block[i]);
    }  
    return result;
  }

  function throwException(errorCode){
    switch(errorCode){
      case _exception.FileLoadFailed:
        throw new Error('Error: Failed to load "'+fileURL+'"');
        break;
      case _exception.EOFReached:
        throw new Error('Error: EOF reached');
        break;
    }
  }
  
  function BinFileReaderImpl_IE(fileURL){
    var vbArr = BinFileReaderImpl_IE_VBAjaxLoader(fileURL);
    _fileContents = vbArr.toArray();    
    _fileSize = _fileContents.length-1;    
    if(_fileSize < 0) throwException(_exception.FileLoadFailed);
    
    this.readByteAt = function(i){
      return _fileContents[i];
    }
  }
  
  function BinFileReaderImpl(fileURL){    
    // Binary charset opt by Marcus Granado 2006 [http://mgran.blogspot.com] 
    var req = new XMLHttpRequest();
    req.open('GET', fileURL, false);
    req.overrideMimeType('text/plain; charset=x-user-defined');
    req.send(null);    
    if (req.status != 200) throwException(_exception.FileLoadFailed);    
    _fileContents = req.responseText;    
    _fileSize = _fileContents.length;
    
    this.readByteAt = function(i){
      return _fileContents.charCodeAt(i) & 0xff;
    }
  }
  
  if(/msie/i.test(navigator.userAgent) && !/opera/i.test(navigator.userAgent))
    BinFileReaderImpl_IE.apply(this, [fileURL]);
  else
    BinFileReaderImpl.apply(this, [fileURL]);
}

document.write('<script type="text/vbscript">\n\
               Function BinFileReaderImpl_IE_VBAjaxLoader(fileName)\n\
               Dim xhr\n\
               Set xhr = CreateObject("Microsoft.XMLHTTP")\n\
               \n\
               xhr.Open "GET", fileName, False\n\
               \n\
               xhr.setRequestHeader "Accept-Charset", "x-user-defined"\n\
               xhr.send\n\
               \n\
               Dim byteArray()\n\
               \n\
               if xhr.Status = 200 Then\n\
               Dim byteString\n\
               Dim i\n\
               \n\
               byteString=xhr.responseBody\n\
               \n\
               ReDim byteArray(LenB(byteString))\n\
               \n\
               For i = 1 To LenB(byteString)\n\
               byteArray(i-1) = AscB(MidB(byteString, i, 1))\n\
               Next\n\
               End If\n\
               \n\
               BinFileReaderImpl_IE_VBAjaxLoader=byteArray\n\
               End Function\n\
               </script>');