/**
 */
function Hits(term, fromIndex, toIndex, fulltextReader, suffixArrayReader) {
  var _term = term;
  var _fromIndex = fromIndex;
  var _toIndex = toIndex;
  var _fulltextReader = fulltextReader;
  var _suffixArrayReader = suffixArrayReader;

  this.get = function(index) {
    if (index < 0) index += this.size();
    index = _fromIndex + index;
    if (index < _toIndex && index >= _fromIndex) {
      var info = _suffixArrayReader.indexToInfo(index);
      var hit = [];
      hit["term"] = _term;
      hit["index"] = index;
      hit["offset"] = info[0];
      hit["recordOffset"] = info[1];
      hit["fieldId"] = info[2];
      hit["fulltextReader"] = _fulltextReader;
      return hit;
    }
    return null;
  }
  
  this.size = function() {
    return _toIndex - _fromIndex;
  }    
}