import { Controller } from "stimulus";
import axios from 'axios';

// TODO: Write a manual if this stays in the code base.
export default class extends Controller {
  static targets = [ "result" ]

  submit(event){

    event.preventDefault();
      const myForm = this.element;
      let formData = new FormData(myForm);
      let controller = this; 

      axios.post(this.data.get("url"), formData)
      .then(function (response) {
        controller.resultTarget.innerHTML = response.data;
        
        return false;
      })
      .catch(function (error) {
        // handle error
        console.log(error);
      })
      .then(function () {
        // always executed
      });
    
  }

}
