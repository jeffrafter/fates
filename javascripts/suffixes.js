/**
 */
function Suffixes(reader, size) {
  var _reader = reader;
  var _base = reader.pos();
  var _size = size;

  this.size = function() {
    return _size;
  }
  
  this.get = function(index) {
    _reader.seek(_base + index * 12);
    var block = _reader.read(12);
    var result = [];
    result[0] = _reader.blockToNumber(block.slice(0, 3));
    result[1] = _reader.blockToNumber(block.slice(4, 7));
    result[2] = _reader.blockToNumber(block.slice(8, 11));
    return result;
  }
  
  this.offset = function(index) {
    // 4 = size of a single long, the suffixes are a sequence of longs that 
    // represent offsets into the fulltext
    _reader.seek(_base + index * 12);
    var block = _reader.read(4);
    return _reader.blockToNumber(block);
  }    
}