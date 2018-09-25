'use babel';

export default class MyPackageView {
  var size = "300px";
  constructor(serializedState) {
    // Create root element
    this.element = document.createElement('div');
    this.element.classList.add('my-package');
    // Create message element
    const message = document.createElement('div');
    message.style.width = size;
    message.textContent = 'Live Chat!';
    message.classList.add('message');
    message.input.onclick = onClick();
    this.element.appendChild(message);
  }

  // Returns an object that can be retrieved when package is activated
  serialize() {

  }

  // Tear down any state and detach
  destroy() {
    this.element.remove();
  }

  getElement() {
    return this.element;
  }

}
