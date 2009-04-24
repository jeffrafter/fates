/**
 */
function FulltextReader(baseURL){
  var _reader = new ChunkedFileReader(baseURL);

  this.getData = function(offset, size) {
    _reader.seek(offset);
    var block = _reader.read(size);
    return _reader.blockToString(block);
  }
  
  this.hitToRecordData = function(hit) {
    _reader.seek(hit["recordOffset"]);
    var block = _reader.read(4);
    var size = _reader.blockToNumber(block);
    _reader.seek(hit["recordOffset"]);
    return _reader.read(size);    
  }
  
  this.getPrimaryKey = function(block) {
    // Primary key is the second offset in the header, stored as a long
    return _reader.blockToNumber(block.slice(4,7));    
  }
  
  this.getFields = function(block) {
    // Header: 8 == total field data size, primary key
    var headerSize = 8;
    var footerSize = 5;
    var size = block.length;
    var index = 0;
    var fields = [];
    var fieldStart = headerSize;
    while (fieldStart <= size - (headerSize + footerSize)) {
      // Fields are structured: data size, data, \0
      fieldSize = _reader.blockToNumber(block.slice(fieldStart,(fieldStart+3)));
      fields[index++] = _reader.blockToString(block.slice((fieldStart+4),(fieldStart+4+fieldSize)));
      fieldStart += fieldSize + 5;
    }
    return fields;      
  }  
}