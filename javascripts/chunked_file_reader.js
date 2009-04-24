/**
 */
function ChunkedFileReader(baseURL){
  var _baseURL = baseURL;  
  var _chunkSize = 1024;
  var _chunks = [];
  var _file = null;
  var _offset = -1;
  
  this.read = function(size) {
    var data = [];
    while (size != null && size > 0) {
      if (_file == null || _file.pos() >= _chunkSize) this.nextChunk();        
      var sizeAvailable = _chunkSize - _file.pos();
      var readSize = size <= sizeAvailable ? size : sizeAvailable;
      data = data.concat(_file.read(readSize));
      size -= readSize;
    }   
    return data;        
  }
  
  this.getc = function() {
    var block = this.read(1);
    return block[0]
  }
  
  this.seek = function(place) {
    this.openChunk(Math.floor(place / _chunkSize));
    _file.seek(place % _chunkSize);    
  }
  
  this.pos = function() {
    if (_file == null) return 0;
    return _file.pos() + (_chunkSize * _offset);
  }
  
  this.openChunk = function(offset) {
    _offset = offset;
    _file = _chunks[_offset];
    if (_file == null) {
      name = "" + _offset;
      while (name.length < 8) name = "0" + name;
      path = _baseURL + "/" + name;
      _file = new BinFileReader(path);
      _chunks[_offset] = _file;
    }      
  }
  
  this.nextChunk = function() {
    this.openChunk(_offset + 1)    
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
    for (var i=0; i<block.length; i++) {
      result += String.fromCharCode(block[i]);
    }  
    return result;
  }
}